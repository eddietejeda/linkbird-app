class DownloadTweetWorker
	include Sidekiq::Worker
	def perform(user_id, token, secret)
    puts "WORKER DOING BIZ"

    tweets = []
    
    client = get_twitter_connection(token, secret )
    home_timeline = client.home_timeline({count: 50})

    home_timeline.each do |t|
      url = t&.urls&.first&.expanded_url.to_s
      
      if url.start_with?("http") && URI.parse(url).host != "twitter.com"
        begin          
          tweets << { user_id: user_id, tweet_id: t.id, tweet: LinkThumbnailer.generate(url) }
        rescue
          puts 'Caught LinkThumbnailer.generate(url) error'
        end
      end  
          
    end
    
    
    Tweet.insert_all(tweets)

	end
end