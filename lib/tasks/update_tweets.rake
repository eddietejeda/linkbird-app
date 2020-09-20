namespace :db do

  desc "This task is called by the Heroku scheduler add-on"
  task :update_tweets => :environment do
    puts "Updating Tweets..."
  
    User.all.each do |user|
    
      if user.cookie_key.empty? || user.encrypted_data.empty?
        logger.error "🔔 keys and encrypted data empty."
        next
      end
      
      user_secrets = JSON.parse(decrypt_data(user.cookie_key, user.encrypted_data))
        
      minutes_since_update = user.minutes_since_update

      if user.present? && minutes_since_update >= 20
        if settings.development?
          TweetWorker.new.perform( user.id, user_secrets['access_token'], user_secrets['access_token_secret'] )
        else
          TweetWorker.perform_async( user.id, user_secrets['access_token'], user_secrets['access_token_secret'] )
        end
      else
        logger.info "🔔 Using cached results."
      end
  end
  
    puts "done."
  end
  
end
