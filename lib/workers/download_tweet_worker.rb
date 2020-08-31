class DownloadTweetWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id, token, secret)
    tweets = []
    client = get_twitter_connection(token, secret )
        
    home_timeline = client.home_timeline({count: 50})

    home_timeline.each do |t|
      url = t&.urls&.first&.expanded_url.to_s
      
      if url.start_with?("http") && URI.parse(url).host != "twitter.com"
        begin          
          tweets << { user_id: user_id, tweet_id: t.id, tweet: LinkThumbnailer.generate(url), created_at: DateTime.now, updated_at: DateTime.now }
        rescue
          puts 'Caught LinkThumbnailer.generate(url) error'
        end
      end        
    end
    
    Tweet.insert_all(tweets, unique_by: :index_tweets_on_tweet_id)
  end
end
