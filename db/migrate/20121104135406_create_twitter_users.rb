class CreateTwitterUsers < ActiveRecord::Migration
  def change
    create_table :twitter_users do |t|
      t.string :provider
      t.string :uid

      t.timestamps
    end
  end
end
