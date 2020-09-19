require 'uri'
# logger = Logger.new(STDOUT)

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


def reload!
  puts "Reloading #{ENV.fetch('ENV')} environment"
  load './config.rb'
end


def preferred_fav_icon(url)
  favicon = YAML.load_file 'config/preferred-fav-icon.yml' if File.exists? 'config/preferred-fav-icon.yml'
  hostname = URI.parse(url).host.gsub("www.", "")
  second_hostname  =  URI.parse(url).host.split(".").drop(1).join(".")
  
  if hostname && favicon.to_h[hostname] 
    favicon.to_h[hostname] 
  elsif second_hostname && favicon.to_h[second_hostname] 
    favicon.to_h[second_hostname] 
  else
    url
  end
end