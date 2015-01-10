class User < ActiveRecord::Base
  has_many :locations_users, dependent: :destroy
  has_many :locations, through: :locations_users
  has_many :uploads
  has_one :comm_setting, inverse_of: :user, dependent: :destroy
  has_one :snapshot, class_name: 'UserSnapshot', inverse_of: :user, dependent: :destroy
  belongs_to :home_base, class_name: 'Location', foreign_key: :home_base_id

  #scope :last_location, ->(){where(locations: {id: locations.maximum(:id)})}

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         #:async,
         :confirmable

  def last_location
    locations.where(locations: {updated_at: locations.maximum(:updated_at)}).first||home_base||Location.default
  end

  def follows
    CommSetting.joins(:comm_peers).where(comm_peers: { peer_id: id, granted_by_peer: true })
  end

  def requested_grant_to_follow
    t = CommPeer.arel_table
    CommSetting.joins(:comm_peers).where(t[:peer_id].eq(id).and(t[:granted_by_peer].eq(nil).or(t[:granted_by_peer].eq(false))))
  end

  def self.create_tmp_user
    User.create(username: tmp_id, email: 'sko', )
  end
end
