class VersionManager

  def initialize master_branch, work_dir_root, user, is_repo_owner=false
    @master = master_branch
    @work_dir = "#{work_dir_root}/#{user.id}#{is_repo_owner ? '_owner' : ''}"
    @git_dir = "#{@work_dir}/.git"
    @git_args = "--git-dir=#{@git_dir} --work-tree=#{@work_dir}"
    @is_repo_owner = is_repo_owner
    
    Dir.mkdir @work_dir unless File.exist? @work_dir
    unless File.exist? @git_dir
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
        `git #{@git_args} config --global credential.helper cache`
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

  def self.hash_for_poi poi
  end

  def self.hash_for_chat poi
  end
end