class ConnectionHandler
 
  # Returns the Queue the ConnectionHandler is bound to
  def self.queue
    return @queue.to_s
  end

  @queue = :auth_queue
  
  # Worker's perform method. Given a the uid and provider
  # the user is found and respective API is called to process there connections
  def self.perform( credentials , uid, provider)
    puts "Delayed Job Triggered for #{uid}" 
    # Extract the user tp from the uid and provider and pass to the respective api
    user = TwitterUser.find_by_uid(uid)
    TwitterAPI.new( credentials, user ).get_connections ; 
    puts "Delayed Job Completed Task #{uid}"
  end

  # Builds User to Object Connections and writes to the database
  def self.build_user_object_connections( connection_info, usertp )
    #Setup the context
    context = ConnectionContext.find_by_name(connection_info['context']['name'])
    if context.nil?
       context = ConnectionContext.create(connection_info['context'])
    end

    # Get all the tp-exist that don't exist yet and filter
    combo = TpObject.batch_find_by_uid_and_context_name(connection_info['connections'].map{ |connection| 
      {'uid' => connection['object']['uid'], 'context_name' => connection['object']['context_name'] }}).zip(connection_info['connections'])
  
    # Extract the known from the unknown tp-objects
    unknown = combo.select{ |tp| tp.first.nil? }
    known = combo.select{  |tp| !tp.first.nil? }

    if unknown.length > 0
      # Transpose and extra the thirdparty objects to create TpObj and replace the nil row
      unknown = unknown.transpose 
      
      object = unknown.last.map{ |last| last['object']}
      unknown.first.replace( TpObject.batch_create( object)  )
      unknown = unknown.transpose
      
      # Combine the the knowns and unknowns....
      combo =  known.concat( unknown )
    end

    # Extract the froms and tos
    froms = combo.select{|tp| tp.last['connection']['from']=='me' and tp.last['connection']['to']=='you' }.map{ |tp| tp.first }
    from_attr = combo.select{|tp| tp.last['connection']['from']=='me' and tp.last['connection']['to']=='you' }.map{ |tp| tp.last['connection']['attributes'] }
    tos = combo.select{ |tp| tp.last['connection']['from']=='you' and tp.last['connection']['to']=='me' }.map{ |tp| tp.first}
    to_attr = combo.select{ |tp| tp.last['connection']['from']=='you' and tp.last['connection']['to']=='me' }.map{ |tp| tp.last['connection']['attributes'] }
    
    # Create the tos and the froms
    Connection.batch_connect!( tos,  [usertp]*tos.length,  [context]*tos.length, to_attr  )
    Connection.batch_connect!(  [usertp]*froms.length , froms,  [ context ]*froms.length , from_attr  )

    # touch the tp
    usertp.touch
  end
  
  # Builds User to User Connections and write to database
  def self.build_user_user_connections( connection_info, usertp )
    followers = []
    follows = []
    connection_info['connections'].each do |connection|
      t1 = TwitterUser.find_or_create_by_uid_and_name_and_image(connection['identity']['uid'].to_s, connection['identity']['name'], connection['identity']['image'])
      if connection['connection']['from'] == 'me'
        follows << t1
      else
        followers << t1
      end
    end
    usertp.followers << followers
    usertp.follows << follows
  end

  # Returns a new Countdown with the counter set to argument n
  def self.countdown(n)
    return Countdown.new(n)
  end

  class Countdown
    def initialize( n )
      @count = n
    end

    def minus_one
      @count -= 1
    end

    def count
      @count
    end      
    
    def add (n)
      @count += n
    end
  end

end
