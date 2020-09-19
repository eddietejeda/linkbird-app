class IconWorker
  include Sidekiq::Worker
  sidekiq_options retry: 0
	
  def perform()

  end
end