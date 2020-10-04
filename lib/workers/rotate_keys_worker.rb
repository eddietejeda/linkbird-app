class RotateKeysWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform(user_id, token, secret, items=25)
    tweets = []


  end
end