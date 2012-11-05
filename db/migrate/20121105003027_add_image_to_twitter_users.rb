class AddImageToTwitterUsers < ActiveRecord::Migration
  def change
    add_column :twitter_users, :image, :string
  end
end
