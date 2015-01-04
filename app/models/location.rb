class Location < ActiveRecord::Base
  has_many :locations_users, dependent: :destroy
  has_many :users, through: :locations_users
  has_one :poi, inverse_of: :location, dependent: :destroy

  # Geocoder.search([l.latitude, l.longitude])
  reverse_geocoded_by :latitude, :longitude# do |obj, results|
#    if geo = results.first
#binding.pry
#      obj.city = geo.city
#      obj.zipcode = geo.postal_code
#      obj.country = geo.country_code
#    end
#  end
  after_validation :reverse_geocode

  def self.default
    # hagen - uni
    Location.new(latitude: 51.3767, longitude: 7.4938)
  end
end
