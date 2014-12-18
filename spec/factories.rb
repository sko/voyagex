include ActionDispatch::TestProcess

FactoryGirl.define do
  
  factory :user do
    sequence(:username) { |n| "user_#{n}" }
    email { "#{username}@factory.com" }
    password 'secret78'
  end
  
  #profile_photo  { fixture_file_upload(Rails.root.join('spec', 'support', 'images', 'restaurant_profile.png'), 'image/png') }

end
