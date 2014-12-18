class UploadComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :upload
  belongs_to :attachment, class_name: 'Upload', inverse_of: :attached_to
  has_many :comments, class_name: 'UploadComment'
end
