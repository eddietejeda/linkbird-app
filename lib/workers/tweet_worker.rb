class TweetWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id, items=25)
    user = User.find_by(id: user_id)
    user.update_tweets(items)
  end
end