class DeleteOldTweetsWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id)
    

    client = get_twitter_bot_connection()

    top_tweet = Tweet.find_by_sql(["SELECT *, SUM((meta->>'favorite_count')::int + (meta->>'retweet_count')::int) AS total 
      FROM tweets 
      WHERE 
      	created_at > current_date - interval '1' day
      GROUP BY id 
      ORDER BY total 
      DESC LIMIT 1"]).first
      
    url = top_tweet.tweet['url']
    content = top_tweet.tweet['title']
    
    client.update("test")
    # client.update("#{content} #{url}")
  end
end


