require 'spec_helper'

feature "edit event presale", js: true do

  context 'event without presale and event date more than two hours in the future' do
    let (:user) {FactoryGirl.create(:user)}

    scenario 'artist enables presale', vcr: true do
      @user = user
      sign_in @user.email, @user.password
      visit root_path
      expect(page).to have_selector '#map'
    end
  end

end
