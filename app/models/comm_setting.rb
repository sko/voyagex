class CommSetting < ActiveRecord::Base
  belongs_to :user
  has_many :comm_peers, dependent: :destroy
  has_many :peers, class_name: 'User', through: :comm_peers # peers follow user

  def followers
    peers.where(comm_peers: { granted_by_peer: true })
  end

  def follow_grant_requests
    t = CommPeer.arel_table
    peers.where(t[:granted_by_peer].eq(nil).or(t[:granted_by_peer].eq(false)))
  end
end
