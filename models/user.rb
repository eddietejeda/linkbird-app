class User < ActiveRecord::Base

  has_many :tweets
    
  def set_subscription_status!
    self.data['premium'] = subscribed?
    
    if self.data["stripe_subscription"]
      subscription = Stripe::Subscription.retrieve(self.data["stripe_subscription"])
    
      self.data["stripe_subscription_status"] = subscription.status
      self.data["stripe_subscription_end_date"] = Time.at(subscription.current_period_end)
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
      
      
  def update_secret_key
    
    
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
    
  
  def subscribed?
    # Needs research. There should be a simpler API call for this. 
    customer = self.data.to_h['stripe_customer']
    if customer
      Stripe::Customer.retrieve(customer).subscriptions.map{|s| 
        s.plan[:active] == true && s.plan[:product] == ENV['STRIPE_PRODUCT_KEY']
      }.first
    end
  end

  def cancel_subscription
    customer = self.data.to_h['stripe_customer']
    subscription = self.data.to_h['stripe_subscription']
    
    if customer
      Stripe::Subscription.delete(subscription)
    end
  end
  
  
  def update_tweets(items=25)
    tweets = []
    
    client = get_twitter_connection(self.secret_data['access_token'], self.secret_data['access_token_secret'])

    home_timeline = client.home_timeline({count: items})
    
    logger.info "Number of new items in timeline #{home_timeline.count}"

    home_timeline.each do |t|
      url = t&.urls&.first&.expanded_url.to_s

      if url.start_with?("http") && URI.parse(url).host != "twitter.com"
        begin
          
          content = LinkThumbnailer.generate(url)

          if content.description.length > 1
            tweets << { 
              user_id: self.id, 
              tweet_id: t.id, 
              tweet_date: t.created_at,
              tweet: content, 
              meta: { 
                screen_name: t.user.screen_name, 
                name: t.user.name, 
                retweet_count: t.retweet_count, 
                favorite_count: t.favorite_count,
                followers_count: t.user.followers_count,
                friends_count: t.user.friends_count,
                listed_count: t.user.listed_count,
                statuses_count: t.user.statuses_count
              },
              created_at: Time.current.getlocal("+00:00"),
              updated_at: Time.current.getlocal("+00:00")
            }
            logger.info "🔔 User: #{self.id} - #{url} - SUCCESS"
          else
            logger.info "🔔 User: #{self.id} - #{url} - SKIPPING"
          end
        rescue => ex
          logger.error "🔔 Error LinkThumbnailer - #{url} Exception: #{ex}"
        end
      end
    end
    
    if tweets.count > 0
      logger.info "🔔 Inserting #{tweets.count}"
      Tweet.insert_all(tweets, unique_by: :index_tweets_on_tweet_id)
    else
      logger.info "🔔 No new URLs on the home timeline"
    end
  end

end