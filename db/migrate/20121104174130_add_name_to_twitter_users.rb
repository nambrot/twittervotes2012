class AddNameToTwitterUsers < ActiveRecord::Migration
  def change
    add_column :twitter_users, :name, :string
  end
end
