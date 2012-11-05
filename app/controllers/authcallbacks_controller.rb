class AuthcallbacksController < ApplicationController
  # before_filter :authenticate_user!, :only => [:create]

  def create
    o = request.env['omniauth.auth']
    logger.info "OAuth Credentials #{ o['credentials'] }"
    
    if o['provider'] == 'twitter'
      user = TwitterUser.find_by_uid(o['uid'])
      user = TwitterUser.create!(:uid => o['uid'], :name => o['info']['nickname'], :image => o['info']['image']) if user.nil?

      if !is_duplicate?( user.created_at, user.updated_at)
        user.touch
        user.delay.fetchConnections( o['credentials'])
      end
      session[:twitter_user_id] = user.id
      redirect_to '/vote'
    end
    # logger.ap o
    # user = User.authenticate_tpsubidentity(o['uid'], o['provider'])
    
    # # CASE: MISMATCH CREDENTIALS
    # if current_user and ( !user.nil? and  user!=current_user )

    #   logger.warn "Mismatching Credentiails Unable to Authorize Request" 
    #   redirect_to request.env['omniauth.origin'] || user_path(current_user) + '/verify', :notice => "The #{params[:provider].capitalize} account belongs to someone else"

    # # CASE: UPDATE VERIFICATIONS
    # elsif current_user and ( user.nil? or user == current_user )
    #   logger.warn "User Authenticated: #{current_user}" 
      
    #   usertp, created_time, updated_time = find_or_create_tpsubid( o, current_user, params[:provider])  
    #   logger.info "Processing TPSubid #{usertp.id}" 
      
    #   # Process Attributes
    #   AttributeHandler.get_attributes( usertp, current_user, o, params[:provider])
      
    #   if !is_duplicate?( created_time, updated_time )
    #      usertp.touch
    #      usertp.delay.fetchConnections( o['credentials'])
    #   end
      
    #   redirect_to request.env['omniauth.origin'] || user_path(current_user) + '/verify', :notice => "Successfully connected"

    # # CASE: LOG IN
    # elsif user
    #     logger.debug "Login Authenticated #{user.id}"
        
    #     session[:user_id] = user.id
    #     usertp = TpSubidentity.find_by_uid_and_context_name(o['uid'], o['provider'])
    #     logger.debug "Logged in with TpsubId #{usertp.id}"

    #     if not is_duplicate?(usertp.created_at, usertp.updated_at)
    #       logger.debug "DELAYING CONNECTION FETCH"
    #       usertp.touch
    #       usertp.delay.fetchConnections(o['credentials'])
    #     end
        
    #     redirect_to user_path(current_user)+'/verify' ||  request.env['omniauth.origin'] , :notice => "Successfully logged in!"
    
    # # CASE: NEW USER
    # else
    #     logger.debug "No User Authenticated creating new user"
    #     password = rand(10**10).to_s(36)
    #     user = User.create!({:password => password, :password_confirmation => password})
    #     session[:user_id] = user.id
    #     session[:new_user] = true
    #     logger.warn "New User created #{user.id}"
        
    #     # Get the Attribute info
    #     o = request.env['omniauth.auth']
        
    #     usertp, created_time, updated_time = find_or_create_tpsubid( o, current_user, params[:provider])  
    #     logger.debug "New UserTP created #{usertp.id}"
        
    #     # Process Attributes
    #     AttributeHandler.get_attributes( usertp, user, o, params[:provider])
        
    #     if !is_duplicate?( created_time, updated_time )
    #        usertp.touch
    #        usertp.delay.fetchConnections( o['credentials'])
    #     end
        
    #     redirect_to user_path(user) + '/verify'
    #   end

  end

  ## Determines whether the call is a duplicate call within the update window of 24 hours
  def is_duplicate?( created_time, updated_time )
    
    if ( updated_time-created_time )/(60) > 600
      logger.debug "Update Window Open, 24 Old"
      false
    elsif ( updated_time- created_time  < 1 )
      logger.debug "Update Window Open, New node" 
      false
    else
      logger.debug "Update Window Closed"
      true
    end
  end

  # This what happens on failure
  def fail
    ap params
    error = "We could not connect to #{params["strategy"].capitalize}"
    logger.warn "OAUTH FAILED #{params}"
    if session[:user_id].nil?
      redirect_to  params["origin"] || root_path , :notice => error
    else
      user = User.find( session[:user_id])
      redirect_to user_path(user), :notice => error
    end
  end

  # Finds or creates tpsubid for with given oauth info
  def find_or_create_tpsubid( o,current_user, provider )
    a = o['extra']['credport'] 

    if a['email'].nil?
      usertp = current_user.add_tpsubidentity(a['identity']['uid'], TpsiContext.find_by_name(provider), a['identity']['credentials'], a['identity']['name'], a['identity']['image'], a['identity']['url'], a['identity']['objecttype'], a['identity']['attributes'])
    else
      usertp = current_user.add_tpsubidentity(a['identity']['uid'], TpsiContext.find_by_name(provider), a['identity']['credentials'], a['identity']['name'], a['identity']['image'], a['identity']['url'], a['identity']['objecttype'], a['identity']['attributes'], a['email'])
    end
        
    # In the event that this tpsubid belongs to a different user 
    if usertp.nil?
      logger.fatal "UNEXPECTED #{current_user.id} TpSubId nil #{provider} "
      return false
    end
    created_time = usertp.created_at;
    updated_time = usertp.updated_at;
    return [ usertp, created_time, updated_time]
  end

end
