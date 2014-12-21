require 'rails_helper'

describe 'Serializer', vcr: true do

  SPEC_BRANCH = 'spec/serializer'

  before(:each) do
    @cur_branch = `git branch`.match(/^\* (.+?)$/m)[1]
    if @cur_branch != SPEC_BRANCH
      if `git branch`.match(/^\s+#{SPEC_BRANCH}$/m).present?
        `git checkout #{SPEC_BRANCH}`
      else
        `git checkout -b #{SPEC_BRANCH}`
      end
    end
  end

  after(:each) do
    if @cur_branch != SPEC_BRANCH
      `git checkout #{@cur_branch}`
    end
  end

  describe '#' do
    it 'creates a dashboard entry' do
#PoiNote(id: integer, poi_id: integer, user_id: integer, text: text, comments_on_id: integer, attachment_id: integer, created_at: datetime, updated_at: datetime)
      cur_branch = `git branch`.match(/^\* (.+?)$/m)[1]

      v1  = <<v1
      poi_note{
        text: null
        comments[
        ]
      }
v1
      File.open(File.join("#{Rails.root}/spec/tmp", 'serialized'), 'w') do |f|
        f.write(v1)
      end

      #expect {
      #  PushNotification.new.reservation_for_request_created request, token
      #}.to change(DashboardEntry, :count).by(1)
    end
  end

end 
