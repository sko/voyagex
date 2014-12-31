class window.VoyageX.MarkerManager

  constructor: (map) ->
    @_map = map
    @_selectedMarker = null
    @_markers = []
    @_showSearchRadius = false
    @_selectedSearchRadius = null
    @_maxZIndex = 0

  add: (poi, callBack, isUserMarker = false) ->
    markerOps = { draggable: isUserMarker,\
                  riseOnHover: true }
    unless isUserMarker
      markerOps.icon = new L.Icon.Default({iconUrl: '/assets/marker-icon-red.png'})
    marker = L.marker([poi.lat, poi.lng], markerOps)
    @_markers.push new VoyageX.Marker(marker, poi, isUserMarker)
    if callBack != null
      marker.on 'click', callBack
      if isUserMarker
        marker.on 'dblclick', callBack
        marker.on 'dragend', callBack
        marker.on 'mouseover', callBack
    marker.addTo(@_map)
    if marker._zIndex > @_maxZIndex
      @_maxZIndex = marker._zIndex+1
      if @_selectedMarker != null
        @_selectedMarker.target().setZIndexOffset @_maxZIndex
    if isUserMarker
      marker._icon.title = marker._leaflet_id
    else
      marker._icon.title = poi.address
    marker

  sel: (replaceMarker, lat, lng, callBack) ->
    # if @_selectedMarker != null && replaceMarker == @_selectedMarker.target()
    #   @_map.removeLayer @_selectedMarker.target()
    if replaceMarker == null
      poi = {lat: lat, lng: lng}
      marker = this.add poi, callBack, true
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

  meta: (marker) ->
    for m in @_markers
      if m.target() == marker
        return {poi: m.poi(), isUserMarker: m.isUserMarker()}
    null

  forPoi: (poiId) ->
    for m in @_markers
      if m.poi().id == poiId
        return {marker: m.target(), poi: m.poi(), isUserMarker: m.isUserMarker()}
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


class VoyageX.Marker

  constructor: (marker, poi, isUserMarker = false) ->
    @_target = marker
    @_poi = poi
    @_isUserMarker = isUserMarker

  target: ->
    @_target

  poi: ->
    @_poi

  isUserMarker: ->
    @_isUserMarker

  setLatLng: (lat, lng) ->
   @_target.setLatLng(L.latLng(lat, lng))
