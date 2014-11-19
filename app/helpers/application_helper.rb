module ApplicationHelper
  
  LETTERS = ('A'..'Z').to_a.freeze
  NUMBERS = (0..9).to_a.freeze
  MIXED = (LETTERS + NUMBERS).freeze

  #
  #
  #
  def is_mobile
    #return true if true
    request.user_agent =~ /Mobile|webOS/
  end
  
  #
  #
  #
  def devise_mapping
    Devise.mappings[:user]
  end

  #
  #
  #
  def tmp_user check_session = true
    return current_user if current_user.present?
    
    if check_session && session[:tmp_user_id].present?
      User.where(id: session[:tmp_user_id]).first || tmp_user(false)
    else
      dummy_username = (0..6).map { MIXED[rand(MIXED.length)] }.join
      dummy_password = (0..8).map { MIXED[rand(MIXED.length)] }.join
      u = User.create(username: dummy_username, password: dummy_password, password_confirmation: dummy_password, email: ADMIN_EMAIL_ADDRESS.sub(/^[^@]+/, dummy_username))
      u.confirm!
      session[:tmp_user_id] = u.id
      u
    end
  end

end