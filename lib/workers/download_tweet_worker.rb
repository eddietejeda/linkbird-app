class DownloadTweetWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id, token, secret)
    tweets = []
    client = get_twitter_connection(token, secret)
        
    home_timeline = client.home_timeline({count: 50})

    home_timeline.each do |t|
      url = t&.urls&.first&.expanded_url.to_s
      
      if url.start_with?("http") && URI.parse(url).host != "twitter.com"
        begin
          tweets << { 
            user_id: user_id, 
            tweet_id: t.id, 
            tweet: LinkThumbnailer.generate(url), 
            tweet_date: t.created_at,
            meta: { screen_name: t.user.screen_name, name: t.user.name, retweet_count: t.retweet_count, favorite_count: t.favorite_count},
            created_at: Time.current.getlocal("+00:00"),
            updated_at: Time.current.getlocal("+00:00")
          }
          puts "🔔 User: #{user_id} - #{url}."
          
        rescue
          puts "🔔 Caught LinkThumbnailer.generate error - #{url}"
        end
      end
    end
    
    if tweets.count > 0
      puts "🔔 Inserting #{tweets.count}"
      Tweet.insert_all(tweets, unique_by: :index_tweets_on_tweet_id)
    else
      puts "🔔 No URLs to add"
    end
  end
end