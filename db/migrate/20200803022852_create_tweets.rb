class CreateTweets < ActiveRecord::Migration[6.0]
  def change
    create_table  :tweets do |t|
      t.integer   :user_id,   null: false
      t.bigint    :tweet_id,  null: false
      t.jsonb     :tweet,     null: false,  default: '{}'

      t.index     [:tweet_id], unique: true
    end
  end
end