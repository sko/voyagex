class User < ActiveRecord::Base
  
  LETTERS = ('A'..'Z').to_a.freeze
  NUMBERS = (0..9).to_a.freeze
  MIXED = (LETTERS + NUMBERS).freeze
  ACCEPTED_FOTO_CONTENT_TYPES = ["application/octet-stream",
                                 "image/jpg",
                                 "image/jpeg",
                                 "image/png",
                                 "image/gif",
                                 "image/webp"]
  TEMP_EMAIL_PREFIX = 'verify@voyagex'
  TEMP_EMAIL_REGEX = /\Averify@voyagex/

  has_many :locations_users, dependent: :destroy
  has_many :locations, through: :locations_users
  has_many :uploads
  has_many :commits
  has_many :identities, dependent: :destroy
  has_many :users_groups, inverse_of: :user
  has_many :groups, :through => :users_groups
  has_one :comm_port, inverse_of: :user, dependent: :destroy
  has_one :snapshot, class_name: 'UserSnapshot', dependent: :destroy
  belongs_to :home_base, class_name: 'Location', foreign_key: :home_base_id

  has_attached_file :foto,
                    url: '/uploads/:attachment/user_:id/:style/:user_foto_file_id'
  
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
         :confirmable, :omniauthable

  def last_location
    locations.where(locations: {updated_at: locations.maximum(:updated_at)}).first||home_base||Location.default
  end

  def follows
    CommPort.joins(:comm_peers).where(comm_peers: { peer_id: id, granted_by_peer: true })
  end

  def requested_grant_to_follow
    t = CommPeer.arel_table
    CommPort.joins(:comm_peers).where(t[:peer_id].eq(id).and(t[:granted_by_peer].eq(nil).or(t[:granted_by_peer].eq(false))))
  end

  def set_base64_file file_json, content_type, file_name
    StringIO.open(Base64.decode64(file_json)) do |data|
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = file_name
      data.content_type = content_type
      self.foto = data
    end
  end

  def is_admin
    email == 'skoeller@gmx.de'
  end

  SOCIAL_NETS_CONFIG.keys.each do |network|
    define_method "#{network}_identity" do
      identities.where(provider: network).first
    end

    define_method "connected_to_#{network}?" do
      send("#{network}_identity").present?
    end
  end

  def self.admin
    User.where(email: 'skoeller@gmx.de').first
  end

  def self.rand_user
    dummy_username = (0..6).map { MIXED[rand(MIXED.length)] }.join
    dummy_password = (0..8).map { MIXED[rand(MIXED.length)] }.join
    avatar_image_url = UserHelper::fetch_random_avatar
    u = User.create(username: dummy_username,
                    password: dummy_password,
                    password_confirmation: dummy_password,
                    email: ADMIN_EMAIL_ADDRESS.sub(/^[^@]+/, dummy_username),
                    search_radius_meters: 1000,
                    snapshot: UserSnapshot.new(location: Location.default, cur_commit: Commit.latest),
                    foto: open(avatar_image_url, allow_redirections: :safe){|t|t.base_uri}
      )
  end

  def self.find_for_oauth(auth, signed_in_resource = nil)
    return nil unless auth.present?

    identity = Identity.find_with_omniauth(auth)
    auth_user = identity.user if identity.present?
    
    email_is_confirmed = auth.info.email && (auth.info.verified || auth.info.verified_email)

    if signed_in_resource.present?
      user = signed_in_resource
      if auth_user.present?
        if auth_user != user
          if (old_identity = user.identities.find{|i|i.provider==identity.provider}).present?
            # user has 2nd identity @ same provider - probably re-registered there
            old_identity.uid = identity.uid
            identity = old_identity # old is already associated with user -> update
          else
            user.identities << identity 
          end
        end
        identity.update_omniauth_attributes auth, email_is_confirmed
      else
        identity = Identity.build_with_omniauth user, auth, auth.info.email, email_is_confirmed
      end
    else
      if auth_user.present?
        user = auth_user
        identity.update_omniauth_attributes auth, email_is_confirmed
      else
        user =(auth.info.email ? User.where(:email => auth.info.email).first : nil) || User.new
        identity = Identity.build_with_omniauth user, auth, auth.info.email, email_is_confirmed
      end
    end

    user.save!

    user
  end

end
