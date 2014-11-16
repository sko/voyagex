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

  def tmp_user
    if session[:tmp_user_id].present?
      User.find session[:tmp_user_id]
    else
      dummy_username = (0..6).map { MIXED[rand(MIXED.length)] }.join
      dummy_password = (0..8).map { MIXED[rand(MIXED.length)] }.join
      u = User.create(username: dummy_username, password: dummy_password, password_confirmation: dummy_password, email: ADMIN_EMAIL_ADDRESS.sub(/^[^@]+/, dummy_username))
      session[:tmp_user_id] = u.id
      u
    end
  end

end