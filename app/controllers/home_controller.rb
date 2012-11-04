class HomeController < ApplicationController

  def logout
    session[:twitter_user_id] = nil
    redirect_to :root
  end

  def vote
    redirect_to :root, :notice => 'You are not logged in' unless current_user
    current_user.vote = params[:vote].to_i if [1,2,3].include? params[:vote].to_i
    current_user.save
    ap current_user.vote
    ap [1,2,3].include? params[:vote].to_i
    ap params[:vote].to_i
    redirect_to :root, :notice => 'Thanks for voting'
  end
end
