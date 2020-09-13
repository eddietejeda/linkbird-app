def current_user
  User.find_by(uid: cookies[:uid], cookie_key: cookies[:cookie_key])
end

def expand_url(url)
  result = Curl::Easy.perform(url) do |curl|
    curl.head = true
    curl.follow_location = true
  end
  result.last_effective_url
end

def get_twitter_connection(token, secret)
  Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_API_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_API_CONSUMER_SECRET"]
    config.access_token        = token 
    config.access_token_secret = secret
  end  
end
