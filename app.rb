# encoding: utf-8
PAGE_LIMIT=20.freeze

class App < Sinatra::Base
  
  # Set up environment
  enable :sessions
  helpers Sinatra::Cookies
  register Sinatra::ActiveRecordExtension
  # register Sinatra::Cache
      
  include Pagy::Backend

  helpers do
    include Pagy::Frontend
  end


  configure :development do
    register Sinatra::Reloader
    set :show_exceptions, true
    # set :sessions, secure: true
  end

  configure :production do
    # set :sessions, domain: 'www.linkbird.app', secure: true
  end

  configure :production, :development do
    use OmniAuth::Builder do
      provider :twitter, ENV['TWITTER_API_CONSUMER_KEY'], ENV['TWITTER_API_CONSUMER_SECRET']
    end  
    set :cookie_options, expires: Time.new + 30.days
  end

    
  before do
    if settings.production?
      redirect "https://#{ENV['PRODUCTION_URL']}" if request.host != ENV['PRODUCTION_URL']
    end    
  end
  
  
  # Home
  get '/' do
    
    @tweets = []
    @user = current_user
    if @user.present?
      
      @show_loading_bar = true
            
      update_frequency_in_minutes = 20
      minutes_since_last_update = @user.minutes_since_last_update

      # For the template
      @user_timezone =  cookies['user_timezone'] 
      @first_download = !@user.tweets.first  
      
      if @first_download && settings.production?
        TweetWorker.perform_async( @user.id, 50 )
      end
      
      @page_limit = PAGE_LIMIT
      @minutes_until_next_update = [(update_frequency_in_minutes - minutes_since_last_update), 0].max
      @pagy, @tweets = pagy(Tweet.where(user_id: @user.id).order(created_at: :desc), items: PAGE_LIMIT)
      
      if @tweets.count.equal? 0
        @alert = "<p>Setting up your account. <br>This may take a minute the first time</p>"
        
      elsif @tweets.count < 15
        @alert = "<p><strong>Don't see many Tweets?</strong></p>
                  <p>That's okay! LinkBird does not go back in your timeline, it only looks forward.
                  This means that over time, LinkBird shows more relevant links. </p>
                  <br>
                  <p>On mobile devices, you can pull down on the page to fetch new links.</p>"
      end
      
    else
      @hide_menu = true
    end

    erb :index
  end

  # Weekly
  get '/popular' do
    @user = authenticate!
    
    @tweets = []
    @page_limit = PAGE_LIMIT
    
    if @user.present?
      @tweets = Tweet.find_by_sql ["SELECT *, SUM((meta->>'favorite_count')::int + (meta->>'retweet_count')::int) AS total 
        FROM tweets 
        WHERE user_id = :user_id AND created_at > current_date - interval '1' day
        GROUP BY id 
        ORDER BY total 
        DESC LIMIT 10", {user_id: @user.id}]
    end
    
    if @tweets.count == 0
      @alert = "<p>Setting up your account. <br>This may take a minute the first time</p>"
    elsif @tweets.count < 10
      @alert = "<p>We need atleast 24 hours of data before this becomes accurate. Check back later.</p>"
    end
    
    erb :popular
  end
  
  # Friend Tweets
  get '/@:screen_name' do
    @public_page = true
    
    @current_logged_in_user = current_user
    
    @user = find_user params[:screen_name] # regexp ^@?(\w){1,15}$
    @tweets = []
    @page_limit = PAGE_LIMIT
    @user_is_public = false
    
    if @user && @user.data['public_profile'] == true
      @user_is_public = true
      @hide_menu = @current_logged_in_user ? false : true
      @pagy, @tweets = pagy(Tweet.where(user_id: @user.id).order(created_at: :desc), items: PAGE_LIMIT)      
    end

    erb :timeline
  end
  
  post '/settings/update' do
    data = JSON.parse request.body.read
    @user = authenticate!
    
    status = false;
    
    # TODO: merge the logic of basic_settings and premium_features into a function
    basic_settings = [
      "public_profile",
      "pull_to_refresh_timeline"
    ]

    if basic_settings.include? (data.keys.first)
      if data.values.first === "true" || data.values.first === "false"
        data_value = (data.values.first == "true")
      else
        data_value = data.values.first.to_i
      end 

      @user.data[data.keys.first] = data_value
      status = true if @user.save!
    end

    premium_features = [
      "update_frequency_in_minutes",
      "tweet_archive_limit"
    ]

    if (premium_features.include? (data.keys.first)) && (@user.is_subscriber?)
      # We only mess with bools and numbers in these toggles
      if data.values.first === "true" || data.values.first === "false"
        data_value = (data.values.first == "true")
      else
        data_value = data.values.first.to_i
      end 
      

      @user.data[data.keys.first] = data_value
      status = true if @user.save!
    end

    
    content_type 'application/json'
    { status: status }.to_json
  end
  
  get '/profile' do
    @user = authenticate!

    if @user
      @page_limit = PAGE_LIMIT
      @subscription_page = true
      @user.update_stripe_user_subscription params[:session_id]       
    end
    
    @user_url = "#{root_domain}/@#{@user.screen_name}"
    erb :profile
  end

  post '/cancel' do
    user = authenticate!
    
    user.cancel_subscription
    user.refresh_account_settings!
    redirect '/profile?canceled=profile-page'      
  end

  get '/(about|privacy|install|terms-of-service)' do
    @filepath = request.env['REQUEST_PATH'].match(/\/([a-zA-Z\-]+)/)[1]
    @content = Kramdown::Document.new(File.read("views/static/#{@filepath}.md")).to_html
    erb :static
  end

  get '/refresh' do
    @user = authenticate!
    now = DateTime.now    
        
    if @user && @user.minutes_since_last_update > 2 # minutes
      logger.info "SUCCESS / User #{@user.id} manually refreshing"
      TweetWorker.perform_async( @user.id, 5 )      
    else
      logger.error "RATE LIMIT / User #{@user.id} manually refreshing"
    end
    
    redirect '/'
  end
  
  
  get '/checkout/setup' do
    content_type 'application/json'
    { publishableKey: ENV['STRIPE_PUBLISHABLE_KEY'], subcriptionPriceId: ENV['STRIPE_PRICE_KEY'] }.to_json
  end

  post '/checkout/session' do
    @user = authenticate!

    content_type 'application/json'
    data = JSON.parse request.body.read
    # Create new Checkout Session for the order
    # Other optional params include:
    # [billing_address_collection] - to display billing address details on the page
    # [customer] - if you have an existing Stripe Customer ID
    # [customer_email] - lets you prefill the email input in the form
    # For full details see https:#stripe.com/docs/api/checkout/sessions/create

    # ?session_id={CHECKOUT_SESSION_ID} means the redirect will have the session ID set as a query param
    # root_domain = ENV['PRODUCTION_URL'] ? "https://#{ENV['PRODUCTION_URL']}" : "http://localhost:9292"
    
    session = Stripe::Checkout::Session.create(
      success_url: "#{root_domain}/profile?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{root_domain}/profile?canceled=checkout-page",
      payment_method_types: ['card'],
      mode: 'subscription',
      line_items: [{
        quantity: 1,
        price: data['subcriptionPriceId'],
      }]
    )

    { sessionId: session['id'] }.to_json
  end

  post '/webhook' do
    @user = authenticate!
    # You can use webhooks to receive information about asynchronous payment events.
    # For more about our webhook events check out https://stripe.com/docs/webhooks.
    webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
    payload = request.body.read
    if !webhook_secret.empty?
      # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      event = nil

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, webhook_secret
        )
      rescue JSON::ParserError => e
        # Invalid payload
        logger.info '⚠️  JSON Parse error.'
        status 400
        return
      rescue Stripe::SignatureVerificationError => e
        # Invalid signature
        logger.info '⚠️  Webhook signature verification failed.'
        status 400
        return
      end
    else
      data = JSON.parse(payload, symbolize_names: true)
      event = Stripe::Event.construct_from(data)
    end
    
    # Get the type of webhook event sent - used to check the status of PaymentIntents.
    event_type = event['type']
    data = event['data']
    data_object = data['object']

    logger.info '🔔  Payment succeeded!' if event_type == 'checkout.session.completed'

    content_type 'application/json'
    { status: 'success' }.to_json
  end
  
  
  # Twitter Auth
  get '/auth/twitter/callback' do
    cookies[:uid] = env['omniauth.auth']['uid']
    cookies[:cookie_key] = SecureRandom.uuid

    user_secrets = {}
    user_secrets['access_token'] = env['omniauth.auth']['credentials']['token']
    user_secrets['access_token_secret'] = env['omniauth.auth']['credentials']['secret']

    user = User.find_by(uid: cookies[:uid])

    if user.nil?
      user = User.create(uid: cookies[:uid], secret_key: "")
    end
    
    if user.secret_key.blank?
      secret_key = SecureRandom.uuid
      user.secret_key = secret_key
    end


    # check screen_name after every login
    client = get_twitter_connection user_secrets['access_token'], user_secrets['access_token_secret']
    user.screen_name = client.user.screen_name

    new_cookie = { 
      browser_id: browser_fingerprint,
      cookie_key: cookies[:cookie_key], 
      last_login: DateTime.now, 
      browser: request.env['HTTP_USER_AGENT']
    }
    
    
    user.cookie_keys = add_or_update_active_cookies(user.cookie_keys, new_cookie)
    user.encrypted_data = encrypt_data(user.secret_key, user_secrets.to_h.to_json.to_s)

    user.save!
    user.refresh_account_settings!

    redirect to('/')    
  end
  
  get '/auth/failure' do    
    case params['message']
    when 'session_expired'
      @alert = "<strong>Error from Twitter</strong> <p>Session expired. Try again</p>"
    when 'invalid_credentials'
      @alert = "<strong>Error from Twitter</strong> <p>You authentication failed or was canceled.</p><p><a href='/'>Try again</a></p>."
    end
    erb :index
  end
  
  get '/auth/twitter/deauthorized' do    
    @alert = "<strong>Error from Twitter</strong> <p>Twitter has deauthorized this app</p>"    
    erb :index
  end
  
  get '/logout' do
    invalidate_session_cookie(cookies[:cookie_key].hash.abs)
    cookies.delete(:uid)
    cookies.delete(:cookie_key)
    redirect '/'
  end
  
  get '/security' do
    @user = authenticate!    
    @login_history = current_user.cookie_keys #.sort_by{|k, v| puts k["last_login"]}.reverse    
    erb :security
  end
  
  
  
  
  
  post '/session/destroy' do 
    content_type 'application/json'
    @user = authenticate!
  
    data = JSON.parse request.body.read
    invalidate_session_cookie(data['public_id'])

    { status: "success" }.to_json    
  end
  
  
  not_found do
    status 404
    @error = "Page not found"
    erb :error
  end

  
  private
  
    def authenticate!
      user = current_user
      if !user
        redirect '/'
      end
      user
    end
    
    def root_domain
      ENV['PRODUCTION_URL'] ? "https://#{ENV['PRODUCTION_URL']}" : "http://localhost:9292"
    end
    
    def pagy_get_vars(collection, vars)
      { 
        count: collection.count,
        page: params["page"],
        items: vars[:items] || PAGE_LIMIT
      }
    end


end