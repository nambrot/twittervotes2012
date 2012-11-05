require 'em-http/middleware/oauth'

# Twitter API with EventMachine for Async calls
class TwitterAPI

  # Given credentials we can create a user specific OAuth API object
  def initialize( credentials, usertp, current_user = nil )
    @credentials = credentials 
    @current_user = current_user
    @twitter_url  = 'https://api.twitter.com'
    @twitter_batch_size = 90 
    @token = credentials['token']
    @secret = credentials['secret']
    
    @usertp = usertp
    @auth = { :query => {"access_token" => @token }}
    @oauth_config  = {
        :consumer_key => 'wftV4JUJk8RVjEryKa9Hw',
        :consumer_secret => 'vVQ0WbZKAHIHTQMXIS2agvaI36ccQrPlKNMlcK7uTo',
        :access_token => @token,
        :access_token_secret => @secret
       }
  end
  
  # Gets IDs, then connection information and pass this to the database
  def get_connections
    @followers_buffer = []
    @friends_buffer = []

    batch_connections

    friends_data = { 'context' => TwitterContext , 'connections' => @friends_buffer  }
    followers_data = { 'context' => TwitterContext , 'connections' => @followers_buffer  }

    if Rails.env != 'production'
      File.open( 'tmp/twitter_friends.json' , 'w'){ |f| f.write( friends_data.to_json ) }
      File.open( 'tmp/twitter_followers.json' , 'w'){ |f| f.write( followers_data.to_json ) }
      File.open( 'tmp/twitter_credentials.json', 'w'){ |f| f.write( @credentials ) }
    end
  
    ConnectionHandler.build_user_user_connections( friends_data , @usertp)
    ConnectionHandler.build_user_user_connections( followers_data , @usertp)
  end
  
  
  # Sends request to twitter for list of followers/friends
  # On callback we dispatch batch requests to the Twitter API
  def batch_connections
    @countdown = ConnectionHandler.countdown(2)
    EventMachine.run do
      
      followers_req = EventMachine::HttpRequest.new(@twitter_url + '/1/followers/ids.json')
      followers_req.use EventMachine::Middleware::OAuth, @oauth_config
      
      friends_req = EventMachine::HttpRequest.new(@twitter_url + '/1/friends/ids.json')
      friends_req.use EventMachine::Middleware::OAuth, @oauth_config
      friends = friends_req.get
      friends.callback do
        raise "Failed to get friends ids " unless friends.response_header.status ==200
        @friend_ids = MultiJson.load( friends.response )['ids']
        @countdown.add( (@friend_ids.length / @twitter_batch_size.to_f ).ceil.to_i )
        @friend_ids.each_slice( @twitter_batch_size ).map{  |batch| dispatch_friends(batch) } 
        stop_if_finished
      end

      followers = followers_req.get
      followers.callback do 
        raise "Failed to get follower  ids " unless followers.response_header.status ==200
        @follower_ids = MultiJson.load( followers.response  )['ids']
        @countdown.add ( ( @follower_ids.length / @twitter_batch_size.to_f ) .ceil.to_i )
        @follower_ids.each_slice(@twitter_batch_size).map{ |batch|  dispatch_followers(batch) }
        stop_if_finished 
      end

      friends.errback do
        puts "Failed to Retrieve Twitter Friends List"
        stop_if_finished
      end

      followers.errback do
        puts "Failed to Retrieve Twitter Follower List"
        stop_if_finished
      end
      
    end
  end

  # Constant for helping to build a Twitter ConnectionContext Info
  TwitterContext = {  'name' => 'twitter-followership' } 

  # dispatch a batch function to twitter with OAuth1.0 Authorization
  # On Callback creates TpSubidenity info hashes and adds that to the friends buffer
  # On Error will retry 3 times before giving up
  def dispatch_friends( ids , tries = 0 )
    

    request = EM::HttpRequest.new( @twitter_url + '/1/users/lookup.json?user_id=' + ids.to_json )
    request.use EM::Middleware::OAuth, @oauth_config 
    
    http = request.get
    http.callback do
      raise "Batch Twitter Friends dispatch #{http.response}" unless http.response_header.status == 200
      puts "Twitter Friend Dispatch Success Countdown: #{@countdown.count}"
      
      friend_info = MultiJson.load( http.response)
      friends_batch  = friend_info.map{|friend| {
          'identity' => {
            'uid' => friend['id'],
            'context_name' => 'twitter',
            'credentials' => {},
            'name' => friend['screen_name'],
            'url' => "http://www.twitter.com/#{friend['screen_name']}",
            'image' => self.class.process_image( friend['profile_image_url'] ) ,
            'objecttype' => 'Twitter Profile',
            'attributes' => {}
          }  ,
            'email' => nil,
          'connection' => {
            'from' => 'me',
            'to' => 'you',
            'attributes' => {}
          }
        }
       }
      @friends_buffer.concat friends_batch
      stop_if_finished
    end
    
    http.errback  do
      if tries <= 3
        dispatch_friends( ids, tries + 1 )
      else
        stop_if_finished
      end
    end

  end
  
  # dispatch a batch function to twitter with OAuth1.0 Authorization
  # On Callback creates TpSubidenity info hashes and adds that to the followers buffer
  # On Error will retry 3 times before giving up
  def dispatch_followers ( ids,  tries = 0  )
    request = EM::HttpRequest.new( @twitter_url + '/1/users/lookup.json?user_id='+ids.to_json )

    request.use EM::Middleware::OAuth, @oauth_config 
  
    http =  request.get
    http.callback do
      raise "Batch Twitter Follower dispatch #{http.response} " unless http.response_header.status == 200
      puts "Twitter Follower Dispatch Successful - Countdown: #{@countdown.count}"
      
      followers_info = MultiJson.load( http.response)
      followers_batch  = followers_info.map{ |follower| {
          'identity' => {
            'uid' => follower['id'],
            'context_name' => 'twitter',
            'credentials' => {},
            'name' => follower['screen_name'],
            'url' => "http://www.twitter.com/#{follower['screen_name']}",
            'image' => self.class.process_image(follower['profile_image_url']),
            'objecttype' => 'Twitter Profile',
            'attributes' => {}
          }  ,
            'email' => nil,
          'connection' => {
            'from' => 'you',
            'to' => 'me',
            'attributes' => {}
          }
        }
       }
      @followers_buffer.concat followers_batch
      stop_if_finished
    end

    http.errback do
      puts "Followers Dispath failed "
      if tries <= 3
        dispatch_followers( ids, tries + 1 )
      else
        stop_if_finished
      end
    end
  end

  
  def self.process_image( image_url )
    image_url
  end

  # Decrements the countdown and turns off the EM Reactor if possible
  def stop_if_finished
    EM.stop if @countdown.minus_one == 0
  end


end
