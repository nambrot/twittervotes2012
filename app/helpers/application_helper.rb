module ApplicationHelper
  def current_user
    if ( @current_user.nil?) or (session[:twitter_user_id] != @current_user.id)
      begin
       @current_user = TwitterUser.find(session[:twitter_user_id]) unless session[:twitter_user_id].nil?
     rescue 
        @current_user = nil
      end
    end
    @current_user 
  end
end
