class PoiNote < ActiveRecord::Base
  belongs_to :poi
  belongs_to :user
  belongs_to :attachment, class_name: 'Upload'#, inverse_of: :attached_to
  belongs_to :comments_on, class_name: 'PoiNote'
  has_many :comments, class_name: 'PoiNote', foreign_key: :comments_on_id
end
