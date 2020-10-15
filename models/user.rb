class User < ActiveRecord::Base

  has_many :tweets
    
  def initialize
    super
    # @client = get_twitter_user_connection(self.secret_data['access_token'], self.secret_data['access_token_secret'])
  end
  
  def refresh_account_settings!
    # these values are only set if subscription has been set by update_stripe_user_subscription
    if self.data["stripe_subscription"]
      subscription = Stripe::Subscription.retrieve(self.data["stripe_subscription"])
      self.data["stripe_subscription_status"] = subscription.status
      self.data["stripe_subscription_end_date"] = Time.at(subscription.current_period_end)
    end

    if !self.data["public_profile"]
      self.data["public_profile"] = true
    end

    if !self.data["following_settings"]
      self.data["following_settings"] = []
    end
    
    if !self.data["pull_to_refresh_timeline"]
      self.data["pull_to_refresh_timeline"] = true
    end
    

    if !self.data["update_frequency_in_minutes"]
      self.data["update_frequency_in_minutes"] = 20
    end

    if !self.data["tweet_archive_limit"]
      self.data["tweet_archive_limit"] = 20
    end
    
    self.save!
  end
  
  def secret_data
    data = "{}"
    if self.secret_key.present? && self.encrypted_data.present?
      data = decrypt_data(self.secret_key, self.encrypted_data)
    end
    JSON.parse(data)
  end
      
      
  def rotate_secret_key
    
  end
  
  def last_login
    DateTime.parse self.data['login_data'].reverse.first
  end
  
  def minutes_since_last_update
    last_tweet = self.tweets.order(created_at: :desc).first

    if last_tweet
      last_tweet_created_at = last_tweet.created_at
    else
      last_tweet_created_at = 30.minutes.ago
    end

    last_update_in_seconds = Time.current.getlocal("+00:00").to_i - last_tweet_created_at.getlocal("+00:00").to_i
    last_update_in_seconds / 60
  end
    

  def is_subscriber?
    self.is_active_subscriber? || self.is_canceled_subscriber?
  end
  
  def is_active_subscriber?
    subscriber = false
    
    if self.data.to_h['stripe_subscription_status']
      subscriber = (self.data.to_h['stripe_subscription_status'] == "active")
    elsif self.is_canceled_subscriber?
      subscriber = true
    end

    subscriber
  end

  def is_canceled_subscriber?
    (self.data.to_h['stripe_subscription_status'] == "canceled") && (self.data.to_h['stripe_subscription_end_date'] > DateTime.now)
  end
  
  def cancel_subscription
    customer = self.data.to_h['stripe_customer']
    subscription = self.data.to_h['stripe_subscription']
    
    if customer
      Stripe::Subscription.delete(subscription)
    end
  end
  
  
  def update_stripe_user_subscription(session_id)
    if session_id
      session = Stripe::Checkout::Session.retrieve(session_id)

      self.data["stripe_customer"]     = session['customer']
      self.data["stripe_subscription"] = session['subscription']

      self.save!
      self.refresh_account_settings!
    end
  end
  
  
  def get_twitter_lists
    @client = get_twitter_user_connection(self.secret_data['access_token'], self.secret_data['access_token_secret'])
    @client.owned_lists(self.screen_name).to_a
  end
  
  
    
  def save_setting(valid_setting_names, setting_name, setting_value)
    
    status = false
    
    if valid_setting_names.include? (setting_name)
      
      if is_boolean_string(setting_name)
        new_setting_value = string_to_boolean(setting_value) # convert to boolean
      elsif is_numeric?(setting_name)
        new_setting_value = setting_value.to_i # convert to Number
      else
        new_setting_value = simple_text(setting_value) # convert to basic alphabetic
      end 

      self.data[setting_name] = new_setting_value
      status = true if self.save!
    end
     
    status 
  end
  
  
  def home_timeline_trending_today
    
    Tweet.find_by_sql ["SELECT *, SUM((meta->>'favorite_count')::int + (meta->>'retweet_count')::int) AS total 
      FROM tweets 
      WHERE user_id = :user_id AND created_at > current_date - interval '1' day
      GROUP BY id 
      ORDER BY total 
      DESC LIMIT 10", {user_id: self.id}]
  end
  
  def get_twitter_list_tweets
    
    
  end
  
  
  
  def download_tweets(count=25)
    client = get_twitter_user_connection(self.secret_data['access_token'], self.secret_data['access_token_secret'])
    tweets = client.home_timeline ({count: count})
    import_tweets(tweets, self.id)
  end

end