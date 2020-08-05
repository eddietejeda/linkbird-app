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
    if current_user

      if cookies["key"].nil?
        cookies["key"] = SecureRandom.uuid
      end
      
      user = User.where(" uid = :uid ", { uid: session[:uid] } ).first_or_create( uid: session[:uid], cookie_key: cookies["key"] ) 
      @first_download = (user && user.tweets.length == 0)
      
      last_tweet = Tweet.order("created_at").last.created_at.getlocal("+00:00") || 20.minutes.ago
      
      if user && (last_tweet < 30.minutes.ago.getlocal("+00:00"))
        if settings.development?
          DownloadTweetWorker.new.perform( user.id, session[:access_token], session[:access_token_secret] )
        else settings.production?
          DownloadTweetWorker.perform_async( user.id, session[:access_token], session[:access_token_secret] )
        end
      else
        puts "Skipping refresh... for now."
      end
      
      @tweets = user.tweets
    end

    erb :index
  end
  
  get '/auth/twitter/callback' do
    session[:uid] = env['omniauth.auth']['uid']
    session[:access_token] = env['omniauth.auth']['credentials']['token']
    session[:access_token_secret] = env['omniauth.auth']['credentials']['secret']
    redirect to('/')
  end
  
  get '/auth/failure' do
    erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
  end
  
  get '/auth/twitter/deauthorized' do
    erb "Twitter has deauthorized this app."
  end
  
  get '/logout' do
    session[:authenticated] = false
    redirect '/'
  end

end