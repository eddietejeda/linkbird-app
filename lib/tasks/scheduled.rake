namespace :db do

  desc "This task is called by the Heroku scheduler add-on"
  task :update_tweets => :environment do
    puts "Updating Tweets"
  
    User.all.each do |user|
      
      if user.secret_key.empty? || user.encrypted_data.empty?
        puts "⛔ Updating Tweets - Current user #{user.id} - Security keys not found."
        next
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
  task :last_login => :environment do
  
    cols = 10.freeze
    
    puts "#{cli_column('Username')} | #{cli_column('Last Login')} | #{cli_column('Tweet Count')} | #{cli_column('Subscriber')}"

    User.all.map do |u| 
      puts "#{cli_column(u.screen_name)} | #{cli_column(prettify_datetime(u.cookie_keys.last.to_h["last_login"]))} | #{cli_column(u.tweets.count)} |  #{cli_column(u.is_subscriber?)}".gsub("\n", "")
    end
  
  end
  
  desc "This task rotates keys"
  task :rotate_user_keys => :environment do
    puts "Rotating keys"
  
    # User.all.each do |user|
    # end
  
    puts "Done."
  end
  
  
  
end