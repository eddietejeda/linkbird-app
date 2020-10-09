def get_twitter_connection(token, secret)
  Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_API_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_API_CONSUMER_SECRET"]
    config.access_token        = token 
    config.access_token_secret = secret
  end  
end



def get_twitter_bot_connection
  Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_BOT_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_BOT_CONSUMER_SECRET"]
    
    config.access_token        = ENV["TWITTER_BOT_ACCESS_TOKEN"] 
    config.access_token_secret = ENV["TWITTER_BOT_ACCESS_TOKEN_SECRET"]
  end  
end

