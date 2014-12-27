class window.VoyageX.MarkerManager

  constructor: (map) ->
    @_map = map
    @_selectedMarker = null
    @_markers = []
    @_showSearchRadius = false
    @_selectedSearchRadius = null

  add: (poi, callBack, isUserMarker = false) ->
    markerOps = { draggable: isUserMarker,\
                  riseOnHover: true }
    unless isUserMarker
      markerOps.icon = new L.Icon.Default({iconUrl: '/assets/marker-icon-red.png'})
    marker = L.marker([poi.lat, poi.lng], markerOps)
    @_markers.push new VoyageX.Marker(marker, isUserMarker)
    if callBack != null
      marker.on 'click', callBack#, marker
      marker.on 'dblclick', callBack
      marker.on 'dragend', callBack
    marker.addTo(@_map)
    if isUserMarker
      marker._icon.title = marker._leaflet_id
    else
      marker._icon.title = poi.address
    marker

  sel: (replaceMarker, lat, lng, callBack) ->
    # if @_selectedMarker != null && replaceMarker == @_selectedMarker.target()
    #   @_map.removeLayer @_selectedMarker.target()
    poi = {lat: lat, lng: lng}
    if replaceMarker == null
      this.add poi, callBack, true
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

  constructor: (marker, isUserMarker = false) ->
    @_target = marker
    @_isUserMarker = isUserMarker

  target: ->
    @_target

  isUserMarker: ->
    @_isUserMarker

  setLatLng: (lat, lng) ->
   @_target.setLatLng(L.latLng(lat, lng))
