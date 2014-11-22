class Upload < ActiveRecord::Base
  belongs_to :user
  belongs_to :location
  has_many :comments, class_name: 'UploadComment', inverse_of: :upload

  has_attached_file :file,
                    url: '/assets/:attachment/:id/:style/:filename'

  validates_attachment :file, presence: true
  validates_attachment_content_type :file, content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif", "image/webp", "application/octet-stream"]

  def set_base64_file file_json, content_type, file_name
    StringIO.open(Base64.decode64(file_json)) do |data|
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = file_name
      data.content_type = content_type
      self.file = data
    end
  end

end
