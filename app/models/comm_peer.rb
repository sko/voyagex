class CommPeer < ActiveRecord::Base
  belongs_to :comm_setting
  belongs_to :peer, class_name: 'User'
end
