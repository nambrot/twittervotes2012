class CreateFollowerships < ActiveRecord::Migration
  def change
    create_table :followerships do |t|
      t.integer :twitter_user_id
      t.integer :follower_id

      t.timestamps
    end
  end
end
