class Poi < ActiveRecord::Base
  belongs_to :location
  has_many :notes, class_name: 'PoiNote', inverse_of: :poi, dependent: :destroy

  def user
    notes.first.user
  end

end
