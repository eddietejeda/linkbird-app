require 'sinatra'
require 'twitter'
require 'twitter-text'
require "onebox"
require "uri"
require "fscache"
require 'omniauth-twitter'
require 'sinatra/reloader' if development?
require "byebug" if development?

class App < Sinatra::Base

  configure do
    enable :sessions

    use OmniAuth::Builder do
      provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
    end
  end

  helpers do
    def current_user
      !session[:uid].nil?
    end
  end



  filecache = FsCache.new(nil, 1, true)
  
  get '/' do
    @tweets = []
    
    if current_user
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV["CONSUMER_KEY"]
        config.consumer_secret     = ENV["CONSUMER_SECRET"]
        config.access_token        = session[:access_token] 
        config.access_token_secret = session[:access_token_secret] 
      end


      home_timeline = filecache.fetch("tweets") do
        client.home_timeline
      end

      # home_timeline = client.home_timeline
      home_timeline.each do |t|

        # content = {}
        # content[:text] = t.text
        # content[:url] = Twitter::TwitterText::Extractor.extract_urls(t.text).first

        url = t&.urls&.first&.expanded_url.to_s
        if url.length && URI.parse(url).host != "twitter.com"
          @tweets << { url: url, preview: Onebox.preview(url).to_s }
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