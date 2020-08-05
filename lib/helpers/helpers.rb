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

def get_twitter_connection(token, secret)
  
  Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["CONSUMER_KEY"]
    config.consumer_secret     = ENV["CONSUMER_SECRET"]
    config.access_token        = token 
    config.access_token_secret = secret
  end  

end