require 'uri'
require 'logger'

logger = Logger.new(STDOUT)

def current_user
  if request.cookies['uid'] && request.cookies['cookie_key']
    User.where("uid = :uid AND cookie_keys @> :cookie_key", {uid: request.cookies['uid'], cookie_key: [{cookie_key: request.cookies['cookie_key']}].to_json }).first
  end
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


def invalidate_session_cookie(public_id)
  user = current_user
  previous_cookie_list = user.cookie_keys
  cookie_to_delete = { public_id: public_id }
  
  new_cookie_list = delete_active_cookie(previous_cookie_list, cookie_to_delete)
  
  user.cookie_keys = new_cookie_list
  user.save!
end

def delete_active_cookie(previous_cookie_list, cookie_to_delete)
  new_cookie_list = []

  previous_cookie_list.each do |c|
    if c['public_id'] == cookie_to_delete[:public_id].to_i
      next
    end
    new_cookie_list << c
  end
    
  new_cookie_list
end


def add_or_update_active_cookies(previous_cookie_list, new_cookie)
  new_cookie_list = []

  if previous_cookie_list.select{|c|c[:public_id] == new_cookie[:public_id]}.length > 0
    # Update
    previous_cookie_list.each do |c|
      current = c
      if c[:public_id] == new_cookie[:public_id]
        current = new_cookie
      end
      new_cookie_list << current
    end
  else
    # New
    new_cookie_list =  previous_cookie_list
    new_cookie_list << new_cookie
  end
    
  new_cookie_list
end

def prettify_user_agent(user_string)
  user_agent = UserAgentParser.parse user_string
  operating_system = user_agent.os
  "#{operating_system.to_s} <br> #{user_agent.to_s}"  
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

