class RemoveProviderFromTwitterUser < ActiveRecord::Migration
  def change
    remove_column :twitter_users, :provider
  end
end
