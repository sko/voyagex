include ActionDispatch::TestProcess

FactoryGirl.define do
  
  factory :user do
    sequence(:username) { |n| "user_#{n}" }
    email { "#{username}@factory.com" }
    password 'secret78'
  end

end
