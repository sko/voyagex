class window.VoyageX.MarkerManager

  constructor: (map) ->
    @_map = map
    @_selectedMarker = null
    @_markers = []
    @_showSearchRadius = false
    @_selectedSearchRadius = null

  add: (lat, lng, callBack) ->
    marker = L.marker([lat, lng], { draggable: true,\
                                    riseOnHover: true })
    @_markers.push new VoyageX.Marker(marker)
    if callBack != null
      marker.on 'click', callBack#, marker
      marker.on 'dragend', callBack
    marker.addTo(@_map)
    marker._icon.title = marker._leaflet_id
    marker

  sel: (replaceMarker, lat, lng, callBack) ->
    # if @_selectedMarker != null && replaceMarker == @_selectedMarker.target()
    #   @_map.removeLayer @_selectedMarker.target()
    if replaceMarker == null
      this.add lat, lng, callBack
    @_selectedMarker = @_markers[@_markers.length - 1]
    @_selectedMarker.setLatLng(lat, lng)
    @_selectedMarker.target()

  get: () ->
    if @_selectedMarker != null then @_selectedMarker.target() else null

  searchBounds: (radiusMeters, map) ->
    if @_selectedSearchRadius != null
      map.removeLayer(@_selectedSearchRadius)
    if radiusMeters <= 0
      return null

    lat = @_selectedMarker.target().getLatLng().lat
    lng = @_selectedMarker.target().getLatLng().lng
    
    conv_factor = (2.0 * Math.PI)/360.0;
    latRad = lat * conv_factor;

    m1 = 111132.92
    m2 = -559.82
    m3 = 1.175
    m4 = -0.0023
    p1 = 111412.84
    p2 = -93.5
    p3 = 0.118
    latlen = m1 + (m2 * Math.cos(2 * latRad)) + (m3 * Math.cos(4 * latRad)) + (m4 * Math.cos(6 * latRad))
    longlen = (p1 * Math.cos(latRad)) + (p2 * Math.cos(3 * latRad)) + (p3 * Math.cos(5 * latRad))
    meterLat = 1.0 / latlen
    meterLng = 1.0 / longlen

    diameterLat = meterLat * radiusMeters
    diameterLng = meterLng * radiusMeters
    inner_square_half_side_length_lat = Math.round(Math.sqrt((2*diameterLat)**2) / 2*10000000)/10000000
    inner_square_half_side_length_lng = Math.round(Math.sqrt((2*diameterLng)**2) / 2*10000000)/10000000
    
    searchBounds = {lng_east: lng-inner_square_half_side_length_lng,\
                    lng_west: lng+inner_square_half_side_length_lng,\
                    lat_south: lat-inner_square_half_side_length_lat,\
                    lat_north: lat+inner_square_half_side_length_lat}

    @_selectedSearchRadius = L.rectangle([[searchBounds.lat_north, searchBounds.lng_west],
                                          [searchBounds.lat_south, searchBounds.lng_east]], {color: '#ff7800', weight: 1})
    @_selectedSearchRadius.addTo(map);
    searchBounds


class VoyageX.Marker

  constructor: (marker) ->
    @_target = marker

  target: ->
    @_target

  setLatLng: (lat, lng) ->
   @_target.setLatLng(L.latLng(lat, lng))
