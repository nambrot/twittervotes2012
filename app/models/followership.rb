class Followership < ActiveRecord::Base
  attr_accessible :follower_id, :twitter_user_id
  belongs_to :twitter_user
  belongs_to :follower, :class_name => 'TwitterUser'

  # include Neoid::Relationship

  # neoidable do |c|
  #   c.relationship start_node: :follower, end_node: :twitter_user, type: :follows
  # end
end
