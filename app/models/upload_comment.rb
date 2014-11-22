class UploadComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :upload
end
