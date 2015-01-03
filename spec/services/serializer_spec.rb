require 'rails_helper'

#
# wd=`pwd` && cd spec/tmp/serializer && gitk && cd $wd
#
describe 'Serializer', vcr: true do

  SPEC_MASTER = 'spec/serializer'
  WORK_DIR_ROOT = "#{Rails.root}/spec/tmp/serializer"

  before(:each) do
    @v_m_u_1 = VersionManager.new SPEC_MASTER, WORK_DIR_ROOT, FactoryGirl.create(:user)
    @v_m_u_2 = VersionManager.new SPEC_MASTER, WORK_DIR_ROOT, FactoryGirl.create(:user)
    @start_branch = @v_m_u_1.cur_branch
  end

  after(:each) do
    @v_m_u_1.set_branch @start_branch
    @v_m_u_2.set_branch @start_branch
  end

  describe '#' do
    it 'creates a dashboard entry' do
#PoiNote(id: integer, poi_id: integer, user_id: integer, text: text, comments_on_id: integer, attachment_id: integer, created_at: datetime, updated_at: datetime)
      v1_branch = 'spec/v1'
      @v_m_u_1.set_branch v1_branch
      v1  = <<v1
[
poi_note[1]{
  text: null
  comments[
  ]
}
]
v1
      v1_file = File.join(@v_m_u_1.work_dir, 'serialized')
      File.open(v1_file, 'w+') { |f| f.write(v1) }
      #@v_m_u_1.add_file v1_file
      @v_m_u_1.add_and_merge_file v1_file, v1_branch
      @v_m_u_1.push
      
      v2_branch = 'spec/v1'
      @v_m_u_2.set_branch v2_branch
      v2  = <<v2
[
poi_note[2]{
  text: null
  comments[
  ]
}
]
v2
      v2_file = File.join(@v_m_u_2.work_dir, 'serialized')
      File.open(v2_file, 'w+') { |f| f.write(v2) }
      @v_m_u_2.add_and_merge_file v2_file, v2_branch
      @v_m_u_2.push

      #expect {
      #  PushNotification.new.reservation_for_request_created request, token
      #}.to change(DashboardEntry, :count).by(1)
    end
  end

end 
