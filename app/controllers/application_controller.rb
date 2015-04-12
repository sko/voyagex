class ApplicationController < ActionController::Base

  before_filter :set_locale, :store_location
  
  protect_from_forgery with: :null_session
#  skip_before_action :verify_authenticity_token, if: :json_request?
    
  include ApplicationHelper
  helper :all
    
  layout :mobile_by_useragent
 
  #
  #
  #
  def set_locale
    first_browser_lang = request.env['HTTP_ACCEPT_LANGUAGE'].sub(/^([a-z]{2}).*/, "\\1") unless request.env['HTTP_ACCEPT_LANGUAGE'].nil?
    I18n.locale = params[:l] || first_browser_lang || I18n.default_locale
    @url_for_extra_options = { :l => I18n.locale }
  end

  #
  #
  #
  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    if (request.fullpath != "/login" &&
        request.fullpath != "/users/sign_in" &&
        request.fullpath != "/users/sign_up" &&
        request.fullpath != "/users/password" &&
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath 
    end
  end

#  def registered_user?
#    tmp_user.last_sign_in_ip.present?
#  end

#protected
#  # @see skip_before_action
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
