module Auth
  class RegistrationsController < Devise::RegistrationsController  

    def create
      @user = User.new params.require(:user).permit(:email, :password, :password_confirmation)
      if @user.save
        # user hast to confirm email-address first, so no sign_in @user
        render "devise/registrations/success", layout: false, formats: [:js], locals: {resource: @user, resource_name: :user}
      else
        warden.custom_failure!
        render "devise/registrations/new", layout: false, formats: [:js], locals: {resource: @user, resource_name: :user}
      end
    end

    def new
      render "devise/registrations/new", layout: false, formats: [:js], locals: {resource: User.new, resource_name: :user}
    end

  end
end
