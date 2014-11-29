class window.VoyageX.MarkerManager

  constructor: (map) ->
    @_map = map
    @_selectedMarker = null
    @_markers = []

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


class VoyageX.Marker

  constructor: (marker) ->
    @_target = marker

  target: ->
    @_target

  setLatLng: (lat, lng) ->
   @_target.setLatLng(L.latLng(lat, lng))
