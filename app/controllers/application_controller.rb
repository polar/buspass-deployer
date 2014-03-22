class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate_deploy_user!
  before_filter :authorize_deploy_user!

  class NotFoundError < Exception

  end

  class NotAuthorized < Exception

  end


  rescue_from NotAuthorized, :with => :not_authorized

  def authorize_deploy_user!
    # We should b authenticated, just make sure we are polare
    raise NotAuthorized if  current_deploy_user.email != "polar@syr.edu"
  end


  def not_authorized(exception)
    flash[:error] =  "You are not authorized"
    redirect_to installations_path
  end

end
