class User < ActiveRecord::Base
  
  ACCEPTED_FOTO_CONTENT_TYPES = ["application/octet-stream",
                                 "image/jpg",
                                 "image/jpeg",
                                 "image/png",
                                 "image/gif",
                                 "image/webp"]

  has_many :locations_users, dependent: :destroy
  has_many :locations, through: :locations_users
  has_many :uploads
  has_one :comm_setting, inverse_of: :user, dependent: :destroy
  has_one :snapshot, class_name: 'UserSnapshot', inverse_of: :user, dependent: :destroy
  belongs_to :home_base, class_name: 'Location', foreign_key: :home_base_id

  has_attached_file :foto,
                    url: '/assets/:attachment/user_:id/:style/:user_foto_file_id'
  
  validates_attachment :foto, presence: true
  validates_attachment_content_type :foto, content_type: User::ACCEPTED_FOTO_CONTENT_TYPES

  Paperclip.interpolates :user_foto_file_id do |attachment, style|
    "foto_#{attachment.instance.id}.#{attachment.original_filename.match(/[^.]+$/)[0]}"
  end

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

  def set_base64_file file_json, content_type, file_name
    StringIO.open(Base64.decode64(file_json)) do |data|
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = file_name
      data.content_type = content_type
      self.foto = data
    end
  end

  def self.create_tmp_user
    User.create(username: tmp_id, email: 'sko', )
  end
end
