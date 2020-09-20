namespace :db do

  desc "This task is called by the Heroku scheduler add-on"
  task :update_tweets => :environment do
    puts "Updating Tweets..."
  
    User.all.each do |user|
    
      puts "Current user #{user.id}"
      
      if user.cookie_key.empty? || user.encrypted_data.empty?
        puts "🔔 keys and encrypted data empty."
        next
      end
      
      user_secrets = user.private_data        

      TweetWorker.perform_async( user.id, user_secrets['access_token'], user_secrets['access_token_secret'] )
  end
  
    puts "done."
  end
  
end
