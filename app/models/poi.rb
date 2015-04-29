class Poi < ActiveRecord::Base
  
  MASTER = 'test/master'
  WORK_DIR_ROOT = "#{Rails.root}/user_repos"

  belongs_to :commit#, dependent: :destroy
  belongs_to :location
  has_many :notes, class_name: 'PoiNote', inverse_of: :poi, dependent: :destroy

  def user
    notes.first.user
  end

end
