class AddUserLimitToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :feedlimit, :integer, default: 25
  end
end
