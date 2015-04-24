class CommPort < ActiveRecord::Base
  belongs_to :user
  has_many :comm_peers, dependent: :destroy
  has_many :peers, class_name: 'User', through: :comm_peers # peers follow user

  def followers
    peers.where(comm_peers: { granted_by_user: true })
  end

  def follow_grant_requests
    t = CommPeer.arel_table
    peers.where(t[:granted_by_user].eq(nil).or(t[:granted_by_user].eq(false)))
  end
end
