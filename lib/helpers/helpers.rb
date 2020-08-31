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

#
# # we never store :access_token or :access_token_secret in the server.
# # they are saved in an encrypted cookie
# # if someone manages manages to find all the keys in the server
# # they would be useless without the encrypted cookie contents on the end-user's browser
# def restore_session(uid)
#   key = User.where(uid: uid).first.cookie_key
#   restore = decrypt_cookie(cookie_name, key)
#   session[:access_token] = key
#   session[:access_token] = restore[:access_token]
#   session[:access_token_secret] = restore[:access_token_secret]
# end