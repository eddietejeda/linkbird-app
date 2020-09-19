def current_user
  User.find_by(uid: cookies[:uid], cookie_key: cookies[:cookie_key])
end

def expand_url(url)
  result = Curl::Easy.perform(url) do |curl|
    curl.head = true
    curl.headers["User-Agent"] = "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:80.0) Gecko/20100101 Firefox/80.0"
    curl.verbose = true
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


def reload!
  logger.info "Reloading #{ENV.fetch('ENV')} environment"
  load './config.rb'
end


def preferred_fav_icon(url)
  favicon = YAML.load_file 'config/preferred-fav-icon.yml' if File.exists? 'config/preferred-fav-icon.yml'
  favicon.to_h[url] ? favicon.to_h[url] : url
end