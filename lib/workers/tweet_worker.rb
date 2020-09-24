class TweetWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id, token, secret, items=25)
    tweets = []
    client = get_twitter_connection(token, secret)
    
    
    # This is temporary as I find a better place to set user name
    u = User.find(user_id)
    new_data = u.data
    if new_data.to_h['twitter_screen_name'].empty?
      new_data['twitter_screen_name'] = client.user.screen_name
      u.data = new_data
      u.save!
    end
    # end
    

    home_timeline = client.home_timeline({count: items})
    
    logger.info "home_timeline count #{home_timeline.count}"

    home_timeline.each do |t|
      url = t&.urls&.first&.expanded_url.to_s

      if url.start_with?("http") && URI.parse(url).host != "twitter.com"
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
                statuses_count: t.user.statuses_count
              },
              created_at: Time.current.getlocal("+00:00"),
              updated_at: Time.current.getlocal("+00:00")
            }
            logger.info "🔔 User: #{user_id} - #{url} - Added content"
          else
            logger.info "🔔 User: #{user_id} - #{url} - Skipping. No content"
          end
        rescue => ex
          logger.error "🔔 Caught LinkThumbnailer.generate error - #{url} Exception: #{ex}"
        end
      end
    end
    
    if tweets.count > 0
      logger.info "🔔 Inserting #{tweets.count}"
      Tweet.insert_all(tweets, unique_by: :index_tweets_on_tweet_id)
    else
      logger.info "🔔 No URLs to add"
    end
  end
end