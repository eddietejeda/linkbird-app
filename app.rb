require 'sinatra'
require 'twitter'
require 'twitter-text'
require "onebox"
require "uri"
require 'curb'
require 'dalli'
require 'omniauth-twitter'
require 'sinatra/reloader' if development?
require "byebug" if development?

class App < Sinatra::Base

  configure do
    enable :sessions

    set :cache, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"],
                      {:username => ENV["MEMCACHIER_USERNAME"],
                       :password => ENV["MEMCACHIER_PASSWORD"]})
    
    use OmniAuth::Builder do
      provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
    end
  end

  helpers do
    def current_user
      !session[:uid].nil?
    end

    def expand_url(url)
      result = Curl::Easy.perform(url) do |curl|
        curl.head = true
        curl.follow_location = true
      end
      result.last_effective_url
    end
    
  end



  
  get '/' do
    @tweets = []
    
    if current_user
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV["CONSUMER_KEY"]
        config.consumer_secret     = ENV["CONSUMER_SECRET"]
        config.access_token        = session[:access_token] # ENV["ACCESS_TOKEN"]  # 
        config.access_token_secret = session[:access_token_secret]  # ENV["ACCESS_TOKEN_SECRET"] # 
      end
      
      home_timeline ||=  settings.cache.fetch(session[:uid]) do
        response = client.home_timeline({count: 50})
        settings.cache.set(session[:uid], response, 1200) # cache for 20 minutes
        response
      end

      home_timeline.each do |t|
        url = t&.urls&.first&.expanded_url.to_s
        if url.start_with?("http") && URI.parse(url).host != "twitter.com"
          @tweets << { url: url, preview: Onebox.preview(expand_url(url)).to_s }
        end
      end
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