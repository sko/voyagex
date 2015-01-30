class VersionManager

  def initialize master_branch, work_dir_root, user, is_repo_owner=false
    @master = master_branch
    @work_dir = "#{work_dir_root}/#{user.id}#{is_repo_owner ? '_owner' : ''}"
    @git_dir = "#{@work_dir}/.git"
    @git_args = "--git-dir=#{@git_dir} --work-tree=#{@work_dir}"
    @is_repo_owner = is_repo_owner
    
    Dir.mkdir @work_dir unless File.exist? @work_dir
    unless File.exist? @git_dir
      # init_local is for testing only
      # TODO: remote
      init_local = true
      if init_local
        #File.open(File.join(@work_dir, 'README.md'), 'w+') do |f|
        #  f.write("This is the git-workdir for user #{user.id}")
        #end
        `git #{@git_args} init`
        #`git #{@git_args} checkout -b #{@master}`
        #`git #{@git_args} add README.md`
        #`git #{@git_args} commit -m 'initial commit'`
        #{}`git #{@git_args} remote add origin https://github.com/sko/voyagex_data`
        `git #{@git_args} remote add origin git@github.com:/sko/voyagex_data`
        `git #{@git_args} fetch`
        `git #{@git_args} checkout #{@master}`
        #{}`git #{@git_args} config --global credential.helper cache`
      else
        `git #{@git_args} clone https://github.com/sko/voyagex_data`
      end
    end
  end

  def work_dir
    @work_dir
  end

  def master
    @master
  end

  def is_repo_owner?
    @is_repo_owner
  end

  def cur_branch
    `git #{@git_args} branch`.match(/^\* (.+?)$/m)[1]
  end

  def cur_commit
    `git #{@git_args} rev-parse HEAD`.strip
  end

  def history
    `git #{@git_args} log --pretty=oneline | grep -o "^[^ ]\\+"`.split
  end

  def first_commit file
    `git #{@git_args} log --pretty=oneline --diff-filter=A -- #{file} | grep -o "^[^ ]\\+"`.strip
  end

  def files_commited commit_hash
    `git #{@git_args} show --pretty="format:" --name-only #{commit_hash}`.split
  end

  def set_branch branch
    return unless branch.present?
    if cur_branch != branch
      push cur_branch
      if `git #{@git_args} branch`.match(/^\s+#{branch}$/m).present?
        `git #{@git_args} checkout #{branch}`
      else
        `git #{@git_args} checkout -b #{branch}`
      end
    end
  end

  def add_file file
    `git #{@git_args} add #{file}`
    `git #{@git_args} commit -m '-'`
  end

  def merge branch
    `git #{@git_args} fetch`
    #`git #{@git_args} merge #{@master}`
    #`git #{@git_args} merge -s resolve #{@master}`
    `git #{@git_args} rebase #{@master}`
    set_branch @master
    `git #{@git_args} merge #{branch}`
  end

  def push branch=nil
    branch = @master unless branch.present? 
    `git #{@git_args} add -u`
    `git #{@git_args} commit -m 'commit before changing branch'`
    `git #{@git_args} fetch`
    # next might fatal: Needed a single revision and invalid upstream origin/#{branch} if branch doesn't exist
    `git #{@git_args} rebase origin/#{branch}`
    `git #{@git_args} push origin #{branch}`
  end

  def add_and_merge_file file, branch
    add_file file
    merge branch
  end

  def add_location location, location_dir = nil
    unless location_dir.present?
      location_dir = "#{work_dir}/location_#{location.id}"
      return false if File.exist? location_dir
    end
    Dir.mkdir location_dir 
    data  = <<data
{
  lat: #{location.latitude}
  lng: #{location.longitude}
  address: '#{location.address}'
}
data
    file = File.join(location_dir, 'data')
    File.open(file, 'w+') { |f| f.write(data) }
    true
  end

  def add_poi poi, poi_dir = nil
    unless poi_dir.present?
      poi_dir = "#{work_dir}/poi_#{poi.id}" 
      return false if File.exist? poi_dir
    end
    Dir.mkdir poi_dir 
    data  = <<data
{
  location_id: #{poi.location.id}
}
data
    file = File.join(poi_dir, 'data')
    File.open(file, 'w+') { |f| f.write(data) }
  end

  def add_poi_note poi, note, note_dir = nil
    unless note_dir.present?
      note_dir = "#{work_dir}/poi_#{poi.id}/note_#{note.id}"
      return false if File.exist? note_dir
    end
    Dir.mkdir note_dir 
    data  = <<data
{
  user_id: #{note.user.id}
  text: #{note.text}
  comments_on_id: #{note.comments_on_id}
  created_at: #{note.created_at}
  updated_at: #{note.updated_at}
}
data
    file = File.join(note_dir, 'data')
    File.open(file, 'w+') { |f| f.write(data) }
    
    #attachment_dir = "#{work_dir}/poi_#{poi.id}/note_#{note.id}/attachment"
    add_attachment poi, note#, attachment_dir unless File.exist? attachment_dir
  end

  def add_attachment poi, note, attachment_dir = nil
    unless attachment_dir.present?
      attachment_dir = "#{work_dir}/poi_#{poi.id}/note_#{note.id}/attachment"
      return false if File.exist? attachment_dir
    end
    Dir.mkdir attachment_dir 
    data  = <<data
{
  created_at: #{note.attachment.created_at}
  updated_at: #{note.attachment.updated_at}
}
data
    file = File.join(attachment_dir, 'data')
    File.open(file, 'w+') { |f| f.write(data) }
  end

  def self.init_version_control_from_db
    master = 'model/master'
    work_dir_root = "#{Rails.root}/version_control"
    admin = User.admin
    vm = VersionManager.new master, work_dir_root, admin
    #
    # user and location will actually not change
    #
    Location.each do |location|
      location_dir = "#{vm.work_dir}/location_#{location.id}"
      add_location location, location_dir unless File.exist? location_dir
    end
    Poi.each do |poi|
      poi_dir = "#{vm.work_dir}/poi_#{poi.id}"
      add_poi poi, poi_dir unless File.exist? poi_dir
      poi.notes.each do |note|
        note_dir = "#{vm.work_dir}/poi_#{poi.id}/note_#{note.id}"
        add_poi_note poi, note, note_dir unless File.exist? note_dir
        #attachment_dir = "#{vm.work_dir}/poi_#{poi.id}/note_#{note.id}/attachment"
        #add_attachment poi, note, attachment_dir unless File.exist? attachment_dir
      end
    end
    `git #{vm.git_args} add -A`
    #{}`git #{@git_args} add -u`
    `git #{@git_args} commit -m 'commit before changing branch'`
    #vm.push
  end

  def self.hash_for_poi poi
  end

  def self.hash_for_chat poi
  end
end
