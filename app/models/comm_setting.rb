class CommSetting < ActiveRecord::Base
  belongs_to :user
  has_many :comm_peers, dependent: :destroy
  has_many :peers, class_name: 'User', through: :comm_peers
end
