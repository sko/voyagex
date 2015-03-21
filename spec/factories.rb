include ActionDispatch::TestProcess

FactoryGirl.define do
  
  factory :user do
    sequence(:username) { |n| "user_#{n}" }
    email { "#{username}@factory.com" }
    password 'secret78'
    confirmed_at { 2.days.ago }
    #snapshot
    foto { fixture_file_upload(Rails.root.join('spec', 'support', 'images', 'foto.png'), 'image/png') }

    after(:create){ |user, evaluator| user.snapshot = FactoryGirl.create :user_snapshot, user: user }

   # required because of 'inverse_of: :snapshot'
    trait :snapshot do
    end
  end
  
  factory :user_snapshot do
    user
    cur_commit {Commit.latest.first || user.snapshot.create_cur_commit}
    location {Location.first || Location.default}
  end
  
  factory :commit do
    user
  end
  
  factory :location do
  end
end
