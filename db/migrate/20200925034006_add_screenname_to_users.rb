class AddScreennameToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :screen_name, :string,  default: ''
  end
end
