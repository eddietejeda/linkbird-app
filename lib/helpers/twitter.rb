require 'link_thumbnailer'

def get_twitter_user_connection(token, secret)
  Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    
    config.access_token        = token 
    config.access_token_secret = secret
  end  
end



def get_twitter_app_connection
  Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_APP_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_APP_CONSUMER_SECRET"]
    
    config.access_token        = ENV["TWITTER_APP_ACCESS_TOKEN"] 
    config.access_token_secret = ENV["TWITTER_APP_ACCESS_TOKEN_SECRET"]
  end  
end


def import_tweets(tweet_list, user_id=1)
  tweets = []
  client = get_twitter_app_connection
  tweet_list.each do |t|
    url = t&.urls&.first&.expanded_url.to_s

    excluded_domains = YAML.load_file('config/exclude.yaml')
    if url.start_with?("http") && !excluded_domains.include?( URI.parse(url).host  )
      begin
        
        content = LinkThumbnailer.generate(url)
        if content.description.length > 1
          tweets << { 
            user_id: user_id, 
            tweet_id: t.id, 
            tweet_date: t.created_at,
            tweet: content, 
            meta: { 
              screen_name: t.user.screen_name, 
              name: t.user.name, 
              retweet_count: t.retweet_count, 
              favorite_count: t.favorite_count,
              followers_count: t.user.followers_count,
              friends_count: t.user.friends_count,
              listed_count: t.user.listed_count,
              statuses_count: t.user.statuses_count,
              profile_photo: download_file(client.user(t.user.screen_name).profile_image_url_https.to_s)
            },
            created_at: Time.current.getlocal("+00:00"),
            updated_at: Time.current.getlocal("+00:00")
          }
          puts "🔔 User: #{user_id} - #{url} - SUCCESS"
        else
          puts "🔔 User: #{user_id} - #{url} - SKIPPING"
        end
      rescue => ex
        puts "🔔 Error LinkThumbnailer - #{url} Exception: #{ex}"
      end
    end
  end
  
  if tweets.count > 0
    puts "🔔 Inserting #{tweets.count}"
    Tweet.insert_all(tweets, unique_by: :index_tweets_on_tweet_id_and_user_id)
  else
    puts "🔔 No new URLs on the home timeline"
  end
end
