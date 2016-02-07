module Auth
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    include ApplicationHelper
    include UserHelper

    def self.provides_callback_for network
      class_eval %Q{
        def #{network}
          @user = User.find_for_oauth(env["omniauth.auth"], current_user)

          if @user.present? && @user.persisted?
            if (@user.sign_in_count == 0)
              channel = 'system'
              enc_key = nil
              msg = { type: :new_user, user: user_json(@user) }
            else
              # channel = 'talk'
              # enc_key = @user.comm_port.channel_enc_key
              # msg = { type: :new_session, userId: @user.id, fci: @user.comm_port.current_faye_client_id, user: user_json(@user) }
              msg = nil
            end
            sign_in_and_redirect @user, event: :authentication
            session.delete :tmp_user_id
            comm_adapter.publish(channel, enc_key, msg, @user) if msg.present?
            session[:vx_id_provider] = '#{network}'
            set_flash_message(:notice, :success, kind: "#{network}".capitalize) if is_navigational_format?
          else
            session["devise.#{network}_data"] = env["omniauth.auth"]
            redirect_to new_user_registration_url
          end
        end
      }
    end

    SOCIAL_NETS_CONFIG.keys.each do |network|
      next if network.match(/_#{Rails.env}$/).present?

      provides_callback_for network
      provides_callback_for "#{network}_mobile"
    end

    # http://sourcey.com/rails-4-omniauth-using-devise-with-twitter-facebook-and-linkedin/
    # we could confirm unconfirmed social-network-email-addresses here
    def after_sign_in_path_for(resource)
  #    if resource.email_verified?
        super resource
  #    else
  #      fans.finish_signup_path(resource)
  #    end
    end

  end
end