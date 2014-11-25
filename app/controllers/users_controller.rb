class UsersController < ApplicationController 

  def change_details
    if current_user.present?
      edit = (!params[:username].present?)
      unless edit
        current_user.update_attribute(:username, params[:username])
      end
      render "users/change_username", formats: [:js], locals: { edit: edit }
      return
    end
    render "users/change_username", formats: [:js], locals: { edit: false }
  end

end