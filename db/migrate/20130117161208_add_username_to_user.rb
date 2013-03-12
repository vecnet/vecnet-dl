class AddUsernameToUser < ActiveRecord::Migration
  def change
    add_column :users, :username, :string, null: false, :default => ''
    add_index :users, :username
  end
end
