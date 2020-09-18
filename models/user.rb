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
      
  def subscribed?
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

end