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
  def lang_change_links request, clear_params = []
    # I18n.locale
    # "http://localhost:3000/search/show_checks_from_now?l=en&user_id=33"
    request_uri = request.env['REQUEST_URI'].sub(/[&]?l=[^&]+([&]?)/, "\\1")
    query_off_idx = request_uri.index('?')
    if query_off_idx.nil?
      lang_change_link_before = request_uri
      lang_change_link_after = ''
    else
      clear_params.each do |c_p|
        request_uri = request_uri.sub(/[?&]?#{c_p}=[^&]*/, '')
      end
      lang_change_link_before = request_uri[0, query_off_idx]
      lang_change_link_after = "#{request_uri[query_off_idx + 1, request_uri.length]}"
    end
    [lang_change_link_before, lang_change_link_after]
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
      avatar_image_data = UserHelper::fetch_random_avatar request
      cur_path = Rails.root.join('public', 'assets', 'fotos', 'random_avatar')
      File.open(cur_path, 'wb'){|file| file.write(avatar_image_data[1])}
      u = User.create(username: dummy_username,
                      password: dummy_password,
                      password_confirmation: dummy_password,
                      email: ADMIN_EMAIL_ADDRESS.sub(/^[^@]+/, dummy_username),
                      search_radius_meters: 1000,
                      snapshot: UserSnapshot.new(location: Location.default, cur_commit: Commit.latest),
                      foto: File.new(cur_path))
      u.confirm!
      session[:tmp_user_id] = u.id
      u
    end
  end

  #
  #
  #
  def shorten_address location, lookup = false
    if location.address.present?
      parts = location.address.split(',')
      if parts.size >= 3
        parts.drop([parts.size - 2, 2].min).join(',').strip
      else
        location.address
      end
    else
      unless location.persisted?
        if lookup
          geo = Geocoder.search([location.latitude, location.longitude])
          address = geo[0].address
          parts = address.split(',')
          return parts.drop([parts.size - 2, 2].min).join(',').strip if parts.size >= 3
        end
      end
      "#{location.latitude}-#{location.longitude}"
    end
  end

end