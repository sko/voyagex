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

  @@default_location = nil

  def self.default
    # hagen - uni
    @@default_location ||= (Location.where(latitude: 51.3766024, longitude: 7.4940061).first || Location.create(latitude: 51.3766024, longitude: 7.4940061))
  end
end
