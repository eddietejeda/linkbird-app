class CreateTweets < ActiveRecord::Migration[6.0]
  def change
    create_table  :tweets do |t|
      t.integer   :user_id,     null: false
      t.bigint    :keys,        null: false,  default: '',  unique: true
      t.jsonb     :tweet,       null: false,  default: '{}'
    end
  end
end