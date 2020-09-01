class UpdateUsersTable < ActiveRecord::Migration[6.0]
  def change
    add_column :tweets, :meta, :jsonb    
  end
end
