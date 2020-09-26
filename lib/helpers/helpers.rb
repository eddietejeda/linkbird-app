require 'uri'
# logger = Logger.new(STDOUT)

def current_user  
  User.find_by(uid: cookies[:uid], cookie_key: cookies[:cookie_key])
end

def find_user(screen_name)
  User.find_by(screen_name: screen_name)
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
  load './bootup.rb'
end


def preferred_fav_icon(url, filepath: "config/preferred-fav-icon.yml")
  favicon = YAML.load_file filepath if File.exists? filepath
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


def format_datetime(datetime, timezone)
  if valid_timezone(timezone)
    datetime.getlocal(timezone).strftime('%b %-d, %Y %l:%M%P')
  else
    datetime.strftime('%b %-d, %Y')
  end
end


def valid_timezone(timezone)
  timezone.to_s.match(/[\-\+]\d\d\:\d\d/)
end