module Auth
  class SessionsController < Devise::SessionsController  
    before_filter :ensure_params_exist, only: [:create]

    def create
      @user = User.find_for_database_authentication(email: params[:user][:email])
      return invalid_login_attempt unless @user
      if @user.valid_password?(params[:user][:password])
        sign_in(@user)
        render "devise/sessions/success", layout: false, formats: [:js], locals: {resource: @user, resource_name: :user}
      else
        render "devise/sessions/new", layout: false, formats: [:js], locals: { resource: @user, resource_name: :user }
      end
    end

    def new
      if request.xhr?
        render "devise/sessions/new", layout: false, formats: [:js], locals: { resource: User.new, resource_name: :user }
      else
        #flash[:exec] = 'show_login_dialog'
        #render "sandbox/index"
        redirect_to root_path(exec: 'show_login_dialog')
      end
    end
    
    def destroy
      @user = current_user
      sign_out @user
      render "devise/sessions/destroyed", layout: false, formats: [:js], locals: { resource: User.new, resource_name: :user }
    end

    protected
    
    def ensure_params_exist
      return unless params[:user][:email].blank? && params[:user][:password].blank?
      redirect_to new_user_session_path, message: 'params missing'
    end
 
    def invalid_login_attempt
      redirect_to new_user_session_path, message: 'invalid login attempt'
    end

  end
end
