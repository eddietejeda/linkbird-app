class TweetWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id, count=25)
    user = User.find_by(id: user_id)
    user.download_tweets(count)
  end
end