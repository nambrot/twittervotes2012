class AddObamaToTwitterUsers < ActiveRecord::Migration
  def change
    add_column :twitter_users, :vote, :integer, :default => 1
  end
end
