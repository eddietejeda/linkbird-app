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
    set :sessions, same_site: :lax, secure: false, path: '/'
  end

  #https://stackoverflow.com/questions/39303353/how-to-set-a-cookie-in-sinatra
  configure :staging do
    set :sessions, same_site: :lax, secure: true, path: '/'
  end

  configure :production do
    # set :sessions, domain: 'linkbird.app', secure: true
    set :sessions, same_site: :lax, secure: true, path: '/'
  end

  configure :production, :development, :staging do
    use OmniAuth::Builder do
      provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
    end  
    set :cookie_options, expires: Time.new + 30.days
  end

  
  
  # Top Articles
  get '/' do    
    @current_user = current_user
    @page_limit = PAGE_LIMIT


    if @current_user.present?
      @tweets = @current_user.get_top_tweets
      
      if @tweets.count == 0
        @alert = render_partial("creating_account")
      elsif @tweets.count < 5
        @alert = render_partial("initial_download")
      end
      
      erb :index
    else
      erb :introduction
    end

  end
  

  # History
  get '/history' do
    @current_user = authenticate!
    @page_limit = PAGE_LIMIT
    @pagy, @tweets = pagy(@current_user.get_history, items: PAGE_LIMIT )


    if @tweets.count == 0
      @alert = render_partial("history_instruction")
    end


    erb :history
  end
  
    
  # Bookmarks
  get '/bookmarks' do
    @current_user = authenticate!
    @page_limit = PAGE_LIMIT
    @pagy, @tweets = pagy(@current_user.get_bookmarks, items: PAGE_LIMIT )

    if @tweets.count == 0
      @alert = render_partial("bookmark_instruction")
    end

    erb :bookmarks
  end
  
    
  get '/settings' do
    @current_user = authenticate!

    if @current_user
      @page_limit = PAGE_LIMIT
      @subscription_page = true
      @current_user.update_stripe_user_subscription params[:session_id]
    end
    
    @user_url = "#{root_domain}/@#{@current_user.screen_name}"
    erb :settings
  end
  
  post '/settings/update' do
    data = JSON.parse request.body.read
    @current_user = authenticate!
    
    setting_name = data.keys.first
    setting_value = data.values.first

    premium_features = [
      "update_frequency_in_minutes",
      "tweet_archive_limit"
    ]
    basic_settings = [
      "public_profile",
      "pull_to_refresh_timeline"
    ]
    
    status = false;
    
    if (@current_user.is_subscriber?) && (premium_features.include? (setting_name))
      status = @current_user.save_setting(premium_features, setting_name, setting_value)      
    else
      status = @current_user.save_setting(basic_settings, setting_name, setting_value)
    end

    content_type 'application/json'
    { status: status }.to_json
  end
    

  post '/cancel' do
    user = authenticate!
    
    user.cancel_subscription
    user.refresh_account_settings!
    redirect '/settings?canceled=settings-page'      
  end


  get '/refresh' do
    @current_user = authenticate!
    now = DateTime.now    
        
    if @current_user && @current_user.minutes_since_last_update > 2 # minutes
      logger.info "SUCCESS / User #{@current_user.id} manually refreshing"
      TweetWorker.perform_async( @current_user.id, 5 )      
    else
      logger.error "RATE LIMIT / User #{@current_user.id} manually refreshing"
    end
    
    redirect '/'
  end
  
  
  get '/checkout/setup' do
    content_type 'application/json'
    { publishableKey: ENV['STRIPE_PUBLISHABLE_KEY'], subcriptionPriceId: ENV['STRIPE_PRICE_KEY'] }.to_json
  end

  post '/checkout/session' do
    @current_user = authenticate!

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
      success_url: "#{root_domain}/settings?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{root_domain}/settings?canceled=checkout-page",
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
    @current_user = authenticate!
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
    # byebug
    if user.secret_key.blank?
      secret_key = SecureRandom.uuid
      user.secret_key = secret_key
    end

    user_email = env['omniauth.auth']['extra']['raw_info']['email']
    
    if user.email != user_email
      user.email = user_email
    end

    # check screen_name after every login
    client = get_twitter_user_connection user_secrets['access_token'], user_secrets['access_token_secret']
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
      @alert = render_partial("session_expired")
    when 'invalid_credentials'
      @alert = render_partial("invalid_credentials")
    end
    erb :index
  end
  
  get '/auth/twitter/deauthorized' do    
    @alert = render_partial("deauthorized")
    erb :index
  end
  
  get '/logout' do
    browser_id = browser_fingerprint
    invalidate_browser_id_cookie(browser_id)
    cookies.delete(:uid)
    cookies.delete(:cookie_key)
    redirect '/'
  end
  
  get '/security' do
    @current_user = authenticate!    
    @login_history = current_user.cookie_keys #.sort_by{|k, v| puts k["last_login"]}.reverse    
    erb :security
  end
  
  post '/session/destroy' do 
    content_type 'application/json'
    @current_user = authenticate!
  
    data = JSON.parse(request.body.read)
    invalidate_browser_id_cookie(data['browser_id'])

    { status: "success" }.to_json    
  end
  

  post '/bookmark/update' do 
    content_type 'application/json'
    @current_user = authenticate!

    data = JSON.parse(request.body.read)    
    { status: @current_user.set_bookmark( data['tweet_id'] )}.to_json    
  end
  


  post '/view/update' do 
    content_type 'application/json'
    @current_user = authenticate!
  
    data = JSON.parse(request.body.read)
    { status: @current_user.set_view( data['tweet_id'] )}.to_json    
  end


  ####################
  # Static Pages
  ####################
  get '/(about|privacy|install|terms-of-service)' do
    @filepath = request.env['REQUEST_PATH'].match(/\/([a-zA-Z\-]+)/)[1]
    @content = Kramdown::Document.new(File.read("views/static/#{@filepath}.md")).to_html
    erb :static
  end


  not_found do
    status 404
    @error = "Page not found"
    erb :error
  end

  
  ####################
  # Private Methods
  ####################
  private
  
    def authenticate!
      
      if !current_user
        redirect '/'
      end
      
      current_user
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