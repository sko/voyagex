class Upload < ActiveRecord::Base
  #belongs_to :user
  belongs_to :poi_note
  belongs_to :entity, polymorphic: true
  #has_many :comments, class_name: 'UploadComment', inverse_of: :upload
  #has_one :attached_to, class_name: 'UploadComment', inverse_of: :attachment

  validates :entity, presence: true
  validates_associated :entity
  
  def file
    entity.file
  end

  def build_entity content_type, build_params = {}
    case content_type.match(/^[^\/]+/)[0]
    when 'image'
      self.entity = UploadEntity::Mediafile.new(build_params.merge!(upload: self))
    else
    end
  end

  # imagemagick complains about image/webp and .webp
  def self.get_attachment_mapping content_type
    case content_type
    when 'image/webp'
      return ['application/octet-stream', 'class']
    else
      return [content_type]
    end
  end
end
