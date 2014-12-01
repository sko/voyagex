module AuthUtils
  extend ActiveSupport::Concern

    included do
      before_filter :store_location
    end

    WARDEN_SESSION_USER_KEY = 'warden.user.reed_user.key'

    def store_location
      # store last url - this is needed for post-login redirect to whatever the user last visited.
      return unless request.get? 
      if (params[:controller] != 'sessions' &&
          params[:controller] != 'passwords' &&
          !request.xhr?) # don't store ajax calls
        session[:previous_url] = request.fullpath 
      end
    end

    def enc_key
      src = ('a'..'z').to_a + (0..9).to_a
      code_length = 8
      (0..code_length).map { src[rand(36)] }.join
    end

end

