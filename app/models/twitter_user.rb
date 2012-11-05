class TwitterUser < ActiveRecord::Base
  attr_accessible :uid, :vote, :name, :image
  include Neoid::Node

  has_many :followerships
  has_many :followers, :through => :followerships

  has_many :followeds, :class_name => 'Followership', :foreign_key => 'follower_id'
  has_many :follows, :through => :followeds, :source => :twitter_user

  has_many :followers_voted, :through => :followerships, :source => :follower, :conditions => 'vote != 1', :uniq => true
  has_many :obama_followers, :through => :followerships, :source => :follower, :conditions => 'vote = 2', :uniq => true
  has_many :romney_followers, :through => :followerships, :source => :follower, :conditions => 'vote = 3', :uniq => true

  has_many :follows_voted, :through => :followeds, :source => :twitter_user, :conditions => 'vote != 1', :uniq => true
  has_many :obama_follows, :through => :followeds, :source => :twitter_user, :conditions => 'vote = 2', :uniq => true
  has_many :romney_follows, :through => :followeds, :source => :twitter_user, :conditions => 'vote = 3', :uniq => true
  
  validates :name, :presence => true
  validates :uid, :presence => true
  validates :image, :presence => true
  
  neoidable do |c|
    c.field :uid
    c.field :vote
    c.search do |s|
      s.index :uid
      s.index :vote
    end
  end

  def at_name
    '@' + name
  end
  def fetchConnections(credentials)
    ConnectionHandler.perform(credentials, uid, 'twitter')
  end
end
