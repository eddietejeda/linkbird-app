class RenameJsonToEncrypted < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :json
    add_column :users, :encrypted_data, :text,  default: ''
  end
end


