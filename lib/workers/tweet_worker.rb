class TweetWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id, items=25)
    tweets = []
    
    user = User.find_by(id: user_id)
    client = get_twitter_connection(user.secret_data['access_token'], user.secret_data['access_token_secret'])

    home_timeline = client.home_timeline({count: items})
    
    logger.info "Number of new items in timeline #{home_timeline.count}"

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
            logger.info "🔔 User: #{user_id} - #{url} - SUCCESS"
          else
            logger.info "🔔 User: #{user_id} - #{url} - SKIPPING"
          end
        rescue => ex
          logger.error "🔔 Error LinkThumbnailer - #{url} Exception: #{ex}"
        end
      end
    end
    
    if tweets.count > 0
      logger.info "🔔 Inserting #{tweets.count}"
      Tweet.insert_all(tweets, unique_by: :index_tweets_on_tweet_id)
    else
      logger.info "🔔 No new URLs on the home timeline"
    end
  end
end