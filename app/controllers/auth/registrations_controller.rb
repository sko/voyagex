module Auth
  class RegistrationsController < Devise::RegistrationsController  

    def new
      render "devise/registrations/new", layout: false, formats: [:js], locals: {resource: User.new, resource_name: :user}
    end

    def create
      user_params = params.require(:user).permit(:email, :password, :password_confirmation)
      if session[:tmp_user_id].present?
        @user = User.where(id: session[:tmp_user_id]).first
        if @user.present?
          @user.attributes = user_params.merge(confirmation_token: nil, confirmed_at: nil)
          # email-change will trigger @user.send_confirmation_instructions
        end
      end
#      t.integer :user_id
#      t.integer :location_id
#      t.float :lat
#      t.float :lng
#      t.string :cur_commit_hash
      @user = User.new(user_params.merge!({search_radius_meters: 1000, snapshot: UserSnapshot.new(location: Location.default)})) unless @user.present?
      if @user.save
        avatar_image_data = UserHelper::fetch_random_avatar request
        cur_path = Rails.root.join('public', 'assets', 'fotos', 'random_avatar')
        File.open(cur_path, 'wb'){|file| file.write(avatar_image_data[1])}
        @user.update_attribute :foto, File.new(cur_path)
        # user has to confirm email-address first, so no sign_in @user
        #redirect_to root_path(exec: 'show_login_dialog_confirm_email')
        render "devise/registrations/success", layout: false, formats: [:js], locals: {resource: @user, resource_name: :user}
      else
        warden.custom_failure!
        render "devise/registrations/new", layout: false, formats: [:js], locals: {resource: @user, resource_name: :user}
      end
    end

  end
end
