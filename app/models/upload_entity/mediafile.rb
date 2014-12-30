class UploadEntity::Mediafile < ActiveRecord::Base
  
  self.table_name = 'upload_entities_mediafiles'
  
  #belongs_to :upload, inverse_of: :entity
  belongs_to :upload, inverse_of: :mediafile
  
  has_attached_file :file,
                    url: '/assets/:attachment/:id/:style/:filename'
  
  validates_attachment :file, presence: true
  validates_attachment_content_type :file, content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif", "image/webp", "application/octet-stream"]
  
  alias_attribute :content_type, :file_content_type

  def set_base64_file file_json, content_type, file_name
    StringIO.open(Base64.decode64(file_json)) do |data|
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = file_name
      data.content_type = content_type
      self.file = data
    end
  end
  
end
