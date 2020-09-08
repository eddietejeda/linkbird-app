# encoding: utf-8
require './config'


class App < Sinatra::Base
  
  # Set up environment
  enable :sessions  
  helpers Sinatra::Cookies
  register Sinatra::ActiveRecordExtension
    
  configure do
    use OmniAuth::Builder do
      provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
    end  
    set :cookie_options, :expires => Time.new + 30.days
  end
  
  get '/' do

    @tweets = []
    # byebug
    if current_user

      update_frequency_in_minutes = 20
      
      # byebug
      user = User.where(" uid = :uid ", { uid: cookies[:uid] } ).first_or_create( uid: cookies[:uid], cookie_key: cookies[:cookie_key] )
      
      last_tweet_created_at = (Tweet.order("created_at").last && Tweet.order("created_at").last.created_at.getlocal("+00:00")) || 30.minutes.ago.getlocal("+00:00")
      last_update_in_minutes = (Time.now.getlocal("+00:00").to_i - last_tweet_created_at.to_i) / 60
      
      if (user && last_update_in_minutes >= 20) || @first_download
        # DownloadTweetWorker.perform_async( user.id, cookies[:access_token], cookies[:access_token_secret] )
        if settings.development?
          DownloadTweetWorker.new.perform( user.id, cookies[:access_token], cookies[:access_token_secret] )
        else settings.production?
          DownloadTweetWorker.perform_async( user.id, cookies[:access_token], cookies[:access_token_secret] )
        end
      else
        puts "Using cached results."
      end

      @next_update_in_minutes =  [(update_frequency_in_minutes - last_update_in_minutes), 0].max
      @first_download = (user && user.tweets.length == 0)
      @tweets = user.tweets.order(tweet_date: :asc).limit(100)
    end

    erb :index
  end
  
  get '/auth/twitter/callback' do
    cookies[:uid] = env['omniauth.auth']['uid']
    cookies[:access_token] = env['omniauth.auth']['credentials']['token']
    cookies[:access_token_secret] = env['omniauth.auth']['credentials']['secret']
    cookies[:cookie_key] = SecureRandom.uuid
    
    redirect to('/')
  end
  
  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end
  
  get '/auth/twitter/deauthorized' do
    erb "Twitter has deauthorized this app."
  end
  
  get '/logout' do
    cookies[:uid] = nil
    cookies[:access_token] = nil
    cookies[:access_token_secret] = nil
    cookies[:cookie_key] = nil
    redirect '/'
  end

end