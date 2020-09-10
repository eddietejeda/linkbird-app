class AddBillingIdToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :data, :json,  default: {}
  end
end
