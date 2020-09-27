class AddSecurityKeysToUsers < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :cookie_key, :secret_key
    add_column :users, :cookie_keys, :jsonb,  default: {}
  end
end


