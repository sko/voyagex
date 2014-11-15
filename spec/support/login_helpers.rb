module Features
  module LoginHelper

    def sign_in login, password
      visit '/'
      find('.click-button', text: 'LOGIN').click
      expect(page).to have_content("Sign in")
      fill_in 'restaurant_login', with: login
      fill_in 'restaurant_password', with: password
      click_button 'Sign In'
      expect(page).to have_content('Welcome')
    end
  end
end
