class User < ActiveRecord::Base
  has_many :locations_users, dependent: :destroy
  has_many :locations, through: :locations_users
  has_many :uploads
  has_one :comm_setting, inverse_of: :user
  has_many :comm_peers, foreign_key: :peer_id, dependent: :destroy

  #scope :last_location, ->(){where(locations: {id: locations.maximum(:id)})}

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         #:async,
         :confirmable

  def last_location
    locations.where(locations: {id: locations.maximum(:id)}).first
  end

  def self.create_tmp_user
    User.create(username: tmp_id, email: 'sko', )
  end
end
