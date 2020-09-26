class DeleteOldTweetsWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id)

    max_tweets = 1000

    user = User.find_by( id: user_id )
    puts "Current user_id=#{user.id} has #{user.tweets.size} tweets"
    if user.tweets.size > max_tweets
      
      oldest_tweet_id = user.tweets.order(id: :desc).limit(max_tweets).last.id
      
      result = user.tweets.where("id < :id", {id: oldest_tweet_id} ).destroy_all
      puts "DELETING #{result.count}"
      
    end

  end
end