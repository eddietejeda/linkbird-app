namespace :db do

  desc "This task is called by the Heroku scheduler add-on"
  task :update_tweets => :environment do
    puts "Updating Tweets"
  
    User.all.each do |user|
      
      if user.cookie_key.empty? || user.encrypted_data.empty?
        puts "🔔 Updating Tweets - Current user #{user.id} - Keys empty."
        next
      else
        puts "🔔 Updating Tweets - Current user #{user.id} - Keys found"        
      end
      
      user_secrets = user.secret_data
      TweetWorker.perform_async( user.id )
    end
  
    puts "Done."
  end
  
  
  
  desc "This task is called by the Heroku scheduler add-on"
  task :delete_old_tweets => :environment do
    puts "Deleting old tweets"
  
    User.all.each do |user|
      DeleteOldTweetsWorker.perform_async( user.id )
    end
  
    puts "Done."
  end
  
  
  
  desc "This task is called by the Heroku scheduler add-on"
  task :rotate_user_keys => :environment do
    puts "Rotating keys"
  
    User.all.each do |user|
    end
  
    puts "Done."
  end
  
  
  
end