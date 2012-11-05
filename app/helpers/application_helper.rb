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

  def neutral_tweet
<<-eos
<a href="https://twitter.com/share" class="twitter-share-button" data-lang="en" data-url="http://twittervotes2012.com" data-text="Just found #TwitterVotes2012. Check out how your Twitter universe votes: "></a>
eos
  end

  def obama_tweet
    <<-eos
    <a href="https://twitter.com/share" class="twitter-share-button" data-lang="en" data-url="http://twittervotes2012.com" data-text="I voted for Obama on #TwitterVotes2012. Check out how your Twitter universe votes: "></a>
    eos
  end

  def romney_tweet
    <<-eos
    <a href="https://twitter.com/share" class="twitter-share-button" data-lang="en" data-url="http://twittervotes2012.com" data-text="I voted for Romney on #TwitterVotes2012. Check out how your Twitter universe votes: "></a>
    eos
  end

  def tweet
    case current_user.vote
    when 1
      return neutral_tweet
    when 2
      return obama_tweet
    when 3
      return romney_tweet
    end
  end
end
