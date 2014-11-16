class Location < ActiveRecord::Base
  has_many :locations_users, dependent: :destroy
  has_many :users, through: :locations_users

  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode
end
