module GeoUtils
  extend ActiveSupport::Concern

  #included do
  #end
  
  # l = User.first.last_location; b = latLngLimits l.latitude, l.longitude, 10
  # "L.rectangle(#{[[b[:lat_north], b[:lng_west]], [b[:lat_south], b[:lng_east]]]}, {color: '#ff7800', weight: 1}).addTo(map);"
  # map.removeLayer(l)
  #
  # http://www.csgnetwork.com/degreelenllavcalc.html
  def latLngLimits lat, lng, radius_meters
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



  def tileYZ latLngLimits, zoomLevel
  end

end

