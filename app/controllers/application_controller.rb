class ApplicationController < ActionController::Base
  protect_from_forgery

  class NotFoundError < Exception

  end

end
