require 'rails_helper'

#
# wd=`pwd` && cd spec/tmp/serializer && gitk && cd $wd
#
describe 'Serializer', vcr: true do

  SPEC_BRANCH = 'spec/serializer'
  WORK_DIR = "#{Rails.root}/spec/tmp/serializer"
  GIT_DIR = "#{WORK_DIR}/.git"
  GIT_ARGS = "--git-dir=#{GIT_DIR} --work-tree=#{WORK_DIR}"

  before(:each) do
    unless File.exist? GIT_DIR
      puts "!!!!!!!!!!! init git in #{WORK_DIR} ..."
      File.open(File.join(WORK_DIR, 'README.md'), 'w+') do |f|
        f.write('This is for Testing only!')
      end
      `git #{GIT_ARGS} init`
      `git #{GIT_ARGS} checkout -b #{SPEC_BRANCH}`
      `git #{GIT_ARGS} add README.md`
      `git #{GIT_ARGS} commit -m 'initial commit'`
    end
    @cur_branch = `git #{GIT_ARGS} branch`.match(/^\* (.+?)$/m)[1]
  end

  after(:each) do
    if @cur_branch != `git #{GIT_ARGS} branch`.match(/^\* (.+?)$/m)[1]
      `git #{GIT_ARGS} checkout #{@cur_branch}`
    end
  end

  def set_branch spec_branch
    cur_branch = `git #{GIT_ARGS} branch`.match(/^\* (.+?)$/m)[1]
    if cur_branch != spec_branch
      if `git #{GIT_ARGS} branch`.match(/^\s+#{spec_branch}$/m).present?
        `git #{GIT_ARGS} checkout #{spec_branch}`
      else
        `git #{GIT_ARGS} checkout -b #{spec_branch}`
      end
    end
  end

  def add v_file
    `git #{GIT_ARGS} add #{v_file}`
    `git #{GIT_ARGS} commit -m '-'`
  end

  def merge v_file, v_branch
    #`git #{GIT_ARGS} merge #{SPEC_BRANCH}`
    #`git #{GIT_ARGS} merge -s resolve #{SPEC_BRANCH}`
    `git #{GIT_ARGS} rebase #{SPEC_BRANCH}`
    set_branch SPEC_BRANCH
    `git #{GIT_ARGS} merge #{v_branch}`
  end

  def add_and_merge v_file, v_branch
    add v_file
    merge v_file, v_branch
  end

  describe '#' do
    it 'creates a dashboard entry' do
#PoiNote(id: integer, poi_id: integer, user_id: integer, text: text, comments_on_id: integer, attachment_id: integer, created_at: datetime, updated_at: datetime)
      v1_branch = 'spec/v1'
      set_branch v1_branch
      v1  = <<v1
ns1;[
ns1;poi_note[1]{
ns1;  text: null
ns1;  comments[
ns1;  ]
ns1;}
ns1;]
v1
      v1_file = File.join(WORK_DIR, 'serialized')
      File.open("#{v1_file}.v1", 'w+') { |f| f.write(v1) }
      File.open(v1_file, 'w+') { |f| f.write(v1) }
      add v1_file

      v2_branch = 'spec/v2'
      set_branch v2_branch
      v2  = <<v2
ns2;[
ns2;poi_note[2]{
ns2;  text: null
ns2;  comments[
ns2;  ]
ns2;}
ns2;]
v2
      v2_file = File.join(WORK_DIR, 'serialized')
      File.open("#{v2_file}.v2", 'w+') { |f| f.write(v2) }
      File.open(v2_file, 'w+') { |f| f.write(v2) }
      add_and_merge v2_file, v2_branch

      set_branch v1_branch
      merge v1_file, v1_branch

      #expect {
      #  PushNotification.new.reservation_for_request_created request, token
      #}.to change(DashboardEntry, :count).by(1)
    end
  end

end 
