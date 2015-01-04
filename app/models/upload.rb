class Upload < ActiveRecord::Base
  #belongs_to :user
  belongs_to :attached_to, class_name: 'PoiNote', foreign_key: :poi_note_id#, inverse_of: :attachment
  belongs_to :entity, polymorphic: true, dependent: :destroy
  belongs_to :mediafile, -> { where uploads: {entity_type: 'UploadEntity::Mediafile'} }, class_name: 'UploadEntity::Mediafile', foreign_key: :entity_id#, inverse_of: :attachment
  #has_many :comments, class_name: 'UploadComment', inverse_of: :upload
  #has_one :attached_to, class_name: 'UploadComment', inverse_of: :attachment
  #alias_attribute :attached_to, :poi_note

  validates :entity, presence: true
  validates_associated :entity
  #validates :attached_to, presence: true
  #validates_associated :attached_to
  
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
