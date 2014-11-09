class ApplicationController < ActionController::Base
  
  protect_from_forgery
    
  include ApplicationHelper
  helper :all
    
  layout :mobile_by_useragent

private

  #
  #
  #
  def mobile_by_useragent
    if is_mobile
      "application.mobile"
    else
      "application"
    end
  end

end
