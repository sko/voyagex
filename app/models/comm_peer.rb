#
# follow users by subscribing to one of their comm_settings
#
class CommPeer < ActiveRecord::Base
  belongs_to :comm_setting
  belongs_to :peer, class_name: 'User' # peers follow a user's comm_setting
end
