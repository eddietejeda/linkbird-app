class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table  :users do |t|
      t.bigint    :uid,         null: false
      t.string    :cookie_key,  null: false
      t.jsonb     :json,        null: false,  default: '{}'
      t.timestamps
    end
  end
end

