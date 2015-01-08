class window.VoyageX.MarkerManager

  constructor: (map) ->
    @_map = map
    @_selectedMarker = null
    @_markers = []
    @_showSearchRadius = false
    @_selectedSearchRadius = null
    @_maxZIndex = 0
    @_userMarkerMouseOver = true

  add: (location, callBack, flags = {isUserMarker: false, isPeerMarker: false}) ->
    markerOps = { draggable: flags.isUserMarker,\
                  riseOnHover: true }
    unless flags.isUserMarker
      if flags.isPeerMarker
        markerOps.icon = new L.Icon.Default({iconUrl: '/assets/marker-icon-yellow.png'})
      else
        markerOps.icon = new L.Icon.Default({iconUrl: '/assets/marker-icon-red.png'})
    marker = L.marker([location.lat, location.lng], markerOps)
    @_markers.push new VoyageX.Marker(marker, location, flags)
    if callBack != null
      marker.on 'click', callBack
      if flags.isUserMarker
        marker.on 'dblclick', callBack
        marker.on 'dragend', callBack
        marker.on 'mouseover', callBack
    marker.addTo(@_map)
    if marker._zIndex > @_maxZIndex
      @_maxZIndex = marker._zIndex+1
      if @_selectedMarker != null
        @_selectedMarker.target().setZIndexOffset @_maxZIndex
    if flags.isUserMarker
      marker._icon.title = marker._leaflet_id
    else
      marker._icon.title = location.address
    marker

  sel: (replaceMarker, lat, lng, callBack) ->
    # if @_selectedMarker != null && replaceMarker == @_selectedMarker.target()
    #   @_map.removeLayer @_selectedMarker.target()
    if replaceMarker == null
      location = {lat: lat, lng: lng}
      marker = this.add location, callBack, true
      @_selectedMarker = @_markers[@_markers.length - 1]
    else
      for m in @_markers
        if m.target() == replaceMarker
          @_selectedMarker = m
          break
      unless @_selectedMarker?
        for m, idx in @_markers
          if m.isUserMarker()
            # TODO clean up
            @_markers.splice idx, 1
            break
        poi = {lat: lat, lng: lng}
        @_selectedMarker = new VoyageX.Marker(replaceMarker, poi, true)
        @_markers.push @_selectedMarker

    @_selectedMarker.target().setZIndexOffset @_maxZIndex        
    @_selectedMarker.setLatLng lat, lng
    @_selectedMarker.target()

  get: () ->
    if @_selectedMarker != null then @_selectedMarker.target() else null

  meta: (leafletMarker) ->
    for m in @_markers
      if m.target() == leafletMarker
        #poi = eval("(" + localStorage.getItem(Comm.StorageController.poiKey({id: m.location.poiId})) + ")")
        poi = APP.storage().get Comm.StorageController.poiKey({id: m.location().poiId})
        return {poi: poi, isUserMarker: m.isUserMarker()}
    null

  userMarkerMouseOver: (enable = null) ->
    if enable == null
      return @_userMarkerMouseOver
    if enable
      unless @_userMarkerMouseOver
        @_userMarkerMouseOver = true
    else
      if @_userMarkerMouseOver
        @_userMarkerMouseOver = false

  forPoi: (poiId) ->
    for m in @_markers
      if m.location().poiId == poiId
        poi = APP.storage().get Comm.StorageController.poiKey({id: m.location().poiId})
        return {marker: m.target(), poi: poi, isUserMarker: m.isUserMarker()}
    null

  searchBounds: (radiusMeters, map) ->
    if @_selectedSearchRadius != null
      map.removeLayer(@_selectedSearchRadius)
    if radiusMeters <= 0
      return null

    lat = @_selectedMarker.target().getLatLng().lat
    lng = @_selectedMarker.target().getLatLng().lng
    
    sBs = searchBounds lat, lng, radiusMeters

    @_selectedSearchRadius = L.rectangle([[sBs.lat_north, sBs.lng_west],
                                          [sBs.lat_south, sBs.lng_east]], {color: '#ff7800', weight: 1})
    @_selectedSearchRadius.addTo(map);
    sBs

  toString: (leafletMarker, meta = null) ->
    unless meta?
      meta = this.meta leafletMarker
    if meta.isUserMarker
      'user_' + leafletMarker._leaflet_id
    else
      'poi['+meta.poi.id+']_' + leafletMarker._leaflet_id

class VoyageX.Marker

  constructor: (marker, location, flags) ->
    @_target = marker
    @_location = location
    @_flags = flags

  target: ->
    @_target

  location: ->
    @_location

#  poi: ->
#    #locations = eval("(" + localStorage.getItem(storeKey) + ")")
#    if @_location.poiId? then getPoi(@_location.poi) else APP.storage().getPoi(@_location.id)

  isUserMarker: ->
    @_flags.isUserMarker

  setLatLng: (lat, lng) ->
   @_target.setLatLng(L.latLng(lat, lng))
