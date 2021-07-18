class AddUniqueForTwoIds < ActiveRecord::Migration[6.0]
  def change
    remove_index :tweets, [:tweet_id]
    add_index :tweets, [:tweet_id, :user_id], unique: true
  end
end