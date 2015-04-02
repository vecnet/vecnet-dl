class AddApiKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :api_key, :string
    add_index "users", ["api_key"], name: "index_users_on_api_key"
  end
end
