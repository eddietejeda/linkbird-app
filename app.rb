# encoding: utf-8

class App < Sinatra::Base
  
  # Set up environment
  enable :sessions
  helpers Sinatra::Cookies
  register Sinatra::ActiveRecordExtension
      
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
    set :sessions, domain: 'linkbird.app', secure: true
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
  
  @@page_limit = 20
  
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
      
      if @first_download
        user_secrets = @user.secret_data
        TweetWorker.perform_async( @user.id, user_secrets['access_token'], user_secrets['access_token_secret'], 50 )
      end
      
      @page_limit = @@page_limit
      @minutes_until_next_update = [(update_frequency_in_minutes - minutes_since_last_update), 0].max
      @pagy, @tweets = pagy(Tweet.where(user_id: @user.id).order(created_at: :desc), items: @@page_limit)
      

      if @tweets.count == 0
        @alert = "<p>Setting up your account. <br>This may take a minute the first time</p>"
        
      elsif @tweets.count < 15
        @alert = "<p><strong>Don't see many Tweets?</strong></p> 
        <p>That's okay! LinkBird does not go back in your timeline, it only looks forward. 
        This means that over time, LinkBird shows more relevant links. </p>
        <br>
        <p>On mobile devices, you can pull down on the page to fetch new links.</p>" 
      end
    end

    erb :index
  end

  # Weekly
  get '/popular' do
    
    @user = current_user
    @tweets = []
    @page_limit = @@page_limit
    
    if @user.present?
      @tweets = Tweet.find_by_sql ["SELECT *, SUM((meta->>'favorite_count')::int + (meta->>'retweet_count')::int) AS total 
        FROM tweets 
        WHERE 
        	user_id = :user_id AND
        	created_at > current_date - interval '5' day
        GROUP BY id 
        ORDER BY total 
        DESC LIMIT 10", {user_id: @user.id}]
    end
    
    if @tweets.count == 0
      @alert = "<p>Setting up your account. <br>This may take a minute the first time</p>"
    elsif @tweets.count < 15
      @alert = "<p>We need atleast 24 hours of data before this becomes accurate. Check back later.</p>"
    end
    
    erb :popular
  end
  
  
  # Friend Tweets
  get '/@:screen_name' do
    
    @user = find_user params['screen_name'] # regexp ^@?(\w){1,15}$
    @tweets = []
    @page_limit = @@page_limit
    @public_page = true
    @user_is_public = false
    
    if @user && @user.data['public'] == true
      @user_is_public = true
      @pagy, @tweets = pagy(Tweet.where(user_id: @user.id).order(created_at: :desc), items: @page_limit)      
    end

    
    erb :index
  end
  
  post '/public_profile' do
    data = JSON.parse request.body.read
    
    @user = current_user    
    @user.data['public'] = (data['public']=='true')
    @user.save!
    
    content_type 'application/json'
    { status: 'success' }.to_json      
  end
  
    
  get '/share' do
    
    @user = current_user

    if @user.screen_name.empty?
      user_secrets = @user.secret_data
      client = get_twitter_connection(user_secrets['access_token'], user_secrets['access_token_secret'])      
      @user.screen_name = client.user.screen_name
      @user.save!
    end
    
    @user_url = "#{root_domain}/@#{@user.screen_name}"
    @user_is_public = (@user.data.to_h['public'] == true)

    erb :share
  end
  
  


  post '/cancel' do
    if current_user
      current_user.cancel_subscription
      current_user.set_subscription_status!
      redirect '/subscription'      
    else
      redirect '/'
    end
  end

  get '/privacy' do
    erb :privacy
  end
  
  get '/terms-of-service' do
    erb :terms_of_service
  end

  get '/refresh' do
    @user = current_user        
    now = DateTime.now    
        
    if @user && @user.minutes_since_last_update > 2 # minutes
      puts "SUCCESS / User #{@user.id} manually refreshing"
      user_secrets = @user.secret_data
      TweetWorker.perform_async( @user.id, user_secrets['access_token'], user_secrets['access_token_secret'], 5 )      
    else
      puts "RATE LIMIT / User #{@user.id} manually refreshing"
    end
    
    
    redirect '/'
  end
  get '/subscription' do
    @user = current_user
    @page_limits = @@page_limit
    if !@user
      redirect '/'      
    end

    session_id = params[:session_id]
    
    if session_id
      session = Stripe::Checkout::Session.retrieve(session_id)
    
      @user.data["stripe_customer"]     = session['customer']
      @user.data["stripe_subscription"] = session['subscription']

      @user.save!
      @user.set_subscription_status!
    end
    
    @subscription_page = true

    erb :subscription
  end

  get '/setup' do
    content_type 'application/json'
    { publishableKey: ENV['STRIPE_PUBLISHABLE_KEY'], basicPrice: ENV['STRIPE_PRICE_KEY'] }.to_json
  end

  post '/create-checkout-session' do
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
      success_url: "#{root_domain}/subscription?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{root_domain}/subscription?cancel=1",
      payment_method_types: ['card'],
      mode: 'subscription',
      line_items: [{
        quantity: 1,
        price: data['priceId'],
      }]
    )

    { sessionId: session['id'] }.to_json
  end

  post '/webhook' do
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
      user = User.create(uid: cookies[:uid], cookie_key: cookies[:cookie_key])
    end

    user.cookie_key = cookies[:cookie_key]
    user.encrypted_data = encrypt_data(cookies[:cookie_key], user_secrets.to_h.to_json.to_s)
    user.save!      

    user.set_subscription_status! if user.present?

    redirect to('/')    
  end
  
  get '/auth/failure' do
    @alert = "<h1>Authentication Failed</h1><h3>message:<h3><pre>#{params}</pre>"
    erb :index
    
  end
  
  get '/auth/twitter/deauthorized' do    
    @alert = "Twitter has deauthorized this app."
    erb :index
  end
  
  get '/logout' do
    cookies.delete(:uid)
    cookies.delete(:access_token)
    cookies.delete(:access_token_secret)
    cookies.delete(:cookie_key)
    redirect '/'
  end
  
  
  private
  
    def root_domain
      ENV['PRODUCTION_URL'] ? "https://#{ENV['PRODUCTION_URL']}" : "http://localhost:9292"
    end
    
    def pagy_get_vars(collection, vars)
      {
        count: collection.count,
        page: params["page"],
        items: vars[:items] || @@page_limit
      }
    end


end