class ApplicationController < ActionController::Base
  
  protect_from_forgery with: :null_session
#  skip_before_action :verify_authenticity_token, if: :json_request?
    
  include ApplicationHelper
  helper :all
    
  layout :mobile_by_useragent

#protected
#
#  def json_request?
#    request.format.json?
#  end

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
