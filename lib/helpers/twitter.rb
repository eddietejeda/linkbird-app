def get_twitter_connection(token, secret)
  Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_API_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_API_CONSUMER_SECRET"]
    config.access_token        = token 
    config.access_token_secret = secret
  end  
end

