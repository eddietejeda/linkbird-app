class AddDateToTweets < ActiveRecord::Migration[6.0]
  def change
    add_column :tweets, :tweet_date, :datetime
  end
end
