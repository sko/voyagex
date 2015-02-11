class UserSnapshot < ActiveRecord::Base
  belongs_to :user
  belongs_to :location
  belongs_to :cur_commit, class_name: 'Commit', foreign_key: :commit_id
end
