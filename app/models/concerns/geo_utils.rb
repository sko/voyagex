module ::GeoUtils
  extend ActiveSupport::Concern

  #included do
  #end
  
  # l = User.first.last_location; b = lat_lng_limits l.latitude, l.longitude, 10
  # "L.rectangle(#{[[b[:lat_north], b[:lng_west]], [b[:lat_south], b[:lng_east]]]}, {color: '#ff7800', weight: 1}).addTo(map);"
  # map.removeLayer(l)
  #
  # http://www.csgnetwork.com/degreelenllavcalc.html
  def lat_lng_limits lat, lng, radius_meters
    latRAD = lat/180 * Math::PI
    m1 = 111132.92
    m2 = -559.82
    m3 = 1.175
    m4 = -0.0023
    p1 = 111412.84
    p2 = -93.5
    p3 = 0.118
    # Calculate the length of a degree of latitude and longitude in meters
    latlen = m1 + (m2 * Math.cos(2 * latRAD)) + (m3 * Math.cos(4 * latRAD)) + (m4 * Math.cos(6 * latRAD))
    longlen = (p1 * Math.cos(latRAD)) + (p2 * Math.cos(3 * latRAD)) + (p3 * Math.cos(5 * latRAD));

    meter_lat = 1.0 / latlen
    meter_lng = 1.0 / longlen

    diameter_lat = meter_lat * radius_meters
    diameter_lng = meter_lng * radius_meters
    
    inner_square_half_side_length_lat = (Math.sqrt((2*diameter_lat)**2) / 2*10000000).round.to_f/10000000
    inner_square_half_side_length_lng = (Math.sqrt((2*diameter_lng)**2) / 2*10000000).round.to_f/10000000
    
    {:lng_east => lng-inner_square_half_side_length_lng,
     :lng_west => lng+inner_square_half_side_length_lng,
     :lat_south => lat-inner_square_half_side_length_lat,
     :lat_north => lat+inner_square_half_side_length_lat}
  end

  # this will save the location or a nearby poi-location with the user
  def nearby_pois user, location, radius_meters = 10, limits_lat_lng = {}
    limits = lat_lng_limits location.latitude, location.longitude, radius_meters
    limits_lat = limits[:lat_south] > limits[:lat_north] ? limits[:lat_north]..limits[:lat_south] : limits[:lat_south]..limits[:lat_north]
    limits_lng = limits[:lng_east] > limits[:lng_west] ? limits[:lng_west]..limits[:lng_east] : limits[:lng_east]..limits[:lng_west]
    limits_lat_lng[:limits_lat] = limits_lat
    limits_lat_lng[:limits_lng] = limits_lng
    nearbys = Poi.joins(:location).where(locations: { latitude: limits_lat, longitude: limits_lng })
  end

  # this will save the location or a nearby poi-location with the user
  def nearby_poi user, location, radius_meters = 10
    # FIXME:
    # 1) when address is available check same address
    # 2) otherwise range
   #nearbys = location.nearbys(0.01)
    limits_lat_lng = {}
    nearbys = nearby_pois user, location, radius_meters, limits_lat_lng
    if nearbys.present?
      # TODO check address, then get closest - not first
      poi = nearbys.first
      user.locations_users.create(location: poi.location) unless user.locations.where(id: poi.location.id).present?
    else
      nearbys = Location.where(locations: { latitude: limits_lat_lng[:limits_lat], longitude: limits_lat_lng[:limits_lng] })
      if nearbys.present?
        # TODO check address, then get closest - not first
        location = nearbys.first
        user.locations_users.create(location: location) unless user.locations.where(id: location.id).present?
      else
        user.locations_users.create(location: location)
        location.reload
      end
      # caller can save it if required
      poi = Poi.new location: location
    end
    poi
  end

  private

  def setNewLocation
  end

end

