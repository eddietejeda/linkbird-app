# encoding: utf-8
require './config'


class App < Sinatra::Base
  
  # Set up environment
  enable :sessions  
  helpers Sinatra::Cookies
  register Sinatra::ActiveRecordExtension
      
  include Pagy::Backend
  helpers do
    include Pagy::Frontend
  end

  configure do
    use OmniAuth::Builder do
      provider :twitter, ENV['TWITTER_API_CONSUMER_KEY'], ENV['TWITTER_API_CONSUMER_SECRET']
    end  
    set :cookie_options, :expires => Time.new + 30.days
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
      update_frequency_in_minutes = 20
            
      user_tweets = @user.tweets.order(created_at: :desc)

      if user_tweets.last
        last_tweet_created_at = user_tweets.last.created_at.getlocal("+00:00")
      else
        last_tweet_created_at = 30.minutes.ago.getlocal("+00:00")
      end

      
      last_update_in_seconds = Time.now.getlocal("+00:00").to_i - last_tweet_created_at.to_i
      last_update_in_minutes = last_update_in_seconds / 60

      @first_download = user_tweets.length == 0
    
      # byebug
      if @first_download || (@user.present? && last_update_in_minutes >= 20)
        DownloadTweetWorker.perform_async( @user.id, cookies[:access_token], cookies[:access_token_secret] )
      else
        puts "🔔 Using cached results."
      end

      # For the template
      @next_update_in_minutes =  [(update_frequency_in_minutes - last_update_in_minutes), 0].max
      @pagy, @tweets = pagy(user_tweets)
    end

    erb :index
  end


  post '/cancel' do
    if current_user
      current_user.cancel_subscription
      current_user.set_subscription_status!
      redirect '/profile'      
    else
      redirect '/'      
    end
  end

  #
  # get '/canceled' do
  #   @user = current_user
  #   if !@user
  #     redirect '/'
  #   end
  #   erb :canceled
  # end


  get '/profile' do
    @user = current_user
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


    erb :profile
  end

  # Fetch the Checkout Session to display the JSON result on the success page
  # get '/checkout-session' do
  #   content_type 'application/json'
  #   session_id = params[:sessionId]
  #
  #   session = Stripe::Checkout::Session.retrieve(session_id)
  #
  #   @user = current_user
  #
  #   @user.data["stripe_customer"]     = session['customer']
  #   @user.data["stripe_subscription"] = session['subscription']
  #
  #   @user.save!
  #
  #   @user.set_subscription_status!
  #
  #   session.to_json
  # end

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
    root_domain = ENV['PRODUCTION_URL'] || "http://localhost:9292"
    
    session = Stripe::Checkout::Session.create(
      success_url: "#{root_domain}/profile?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{root_domain}/profile?cancel=1",
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
        status 400
        return
      rescue Stripe::SignatureVerificationError => e
        # Invalid signature
        puts '⚠️  Webhook signature verification failed.'
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

    puts '🔔  Payment succeeded!' if event_type == 'checkout.session.completed'

    content_type 'application/json'
    { status: 'success' }.to_json
  end
  
  
  
  # Twitter Auth
  get '/auth/twitter/callback' do
    cookies[:uid] = env['omniauth.auth']['uid']
    cookies[:access_token] = env['omniauth.auth']['credentials']['token']
    cookies[:access_token_secret] = env['omniauth.auth']['credentials']['secret']
    cookies[:cookie_key] = SecureRandom.uuid
    
    user = User.find_by(uid: cookies[:uid])
    
    if user.nil?
      User.create(uid: cookies[:uid], cookie_key: cookies[:cookie_key])
    else
      user.cookie_key = cookies[:cookie_key]
      user.save!      
    end
    
    
    user.set_subscription_status! if user.present?

    redirect to('/')
  end
  
  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end
  
  get '/auth/twitter/deauthorized' do
    erb "Twitter has deauthorized this app."
  end
  
  get '/logout' do
    cookies.delete(:uid)
    cookies.delete(:access_token)
    cookies.delete(:access_token_secret)
    cookies.delete(:cookie_key)
    redirect '/'
  end
  
  
  private
  
  def pagy_get_vars(collection, vars)
    {
      count: collection.count,
      page: params["page"],
      items: vars[:items] || 10
    }
  end


end