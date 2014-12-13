class window.VoyageX.Main
  
  @_SINGLETON = null
  @_STORAGE_CONTROLLER = null
  @_MAP_CONTROL = null
  @_MARKER_MANAGER = null

  constructor: (cacheStrategy, mapOptions, offlineZooms, online) ->
    Main._SINGLETON = this
    @_initState = 0
    $(window.document).ready () ->
        Main.instance()._init cacheStrategy, mapOptions, offlineZooms, online

  _init: (cacheStrategy, mapOptions, offlineZooms, online) ->
    Main.instance()._initState += 1
    switch Main.instance()._initState
      when 1
        Main._STORAGE_CONTROLLER = new Comm.StorageController((initError) ->
            console.log 'StorageController initialized FileSystem with message: '+(if initError then 'FAILED' else 'OK')
            #if error
            #else
            Main.instance()._init cacheStrategy, mapOptions, offlineZooms, online
          )
#      comm = new Comm.Comm($('#current_user_id').val(),
#                           [['/talk', talkCB, window.VoyageX.CHANNEL_ENC_KEY],
#                            ['/map_events', mapEventsCB, window.VoyageX.CHANNEL_ENC_KEY],
#                            ['/uploads', uploadsCB, window.VoyageX.CHANNEL_ENC_KEY]],
#                           window.VoyageX.SYS_CHANNEL_ENC_KEY,
#                           systemCB)
      when 2
        Main._MAP_CONTROL = new VoyageX.MapControl cacheStrategy, mapOptions, offlineZooms, online
        Main._MARKER_MANAGER = new VoyageX.MarkerManager(Main.map())
#      if navigator.geolocation 
#        navigator.geolocation.getCurrentPosition(initPositionCB, (error) ->
#            alert('geolocation timed out - manual selection required.\nsetting default location...')
#            initPositionCB { coords: { latitude: defaultLatLng[0], longitude: defaultLatLng[1] } }
#        , { enableHighAccuracy: true, timeout : 10000 })
#      #VoyageX.Main.map().on('locationfound', (e) ->
#      #    alert('found location...')
#      #  )
#      #VoyageX.Main.map().on('locationerror', (e) ->
#      #    alert('geolocation timed out - manual selection required.\nsetting default location...')
#      #  )
        VoyageX.Main.map().on 'click', (event) ->
          address = null
          setSelectedPositionLatLng Main.markerManager().get()||Main.markerManager().add(event.latlng.lat, event.latlng.lng, markerEventsCB), event.latlng.lat, event.latlng.lng, address
          publishPosition()
        VoyageX.Main.map().on('zoomend', (e) ->
            zoomEnd(e);
          )
        if window.isMobile()
          VoyageX.Main.map().invalidateSize({
              reset: true,
              pan: false,
              animate: false
            })
        initPositionCB { coords: { latitude: defaultLatLng[0], longitude: defaultLatLng[1] } }
        $('#zoom_level').html('<span style="color:white;">zoom: '+VoyageX.Main.map().getZoom()+'</span>')
        # next statement removes value from inputs!!
        $("#network_state").buttonset()
        $('button[value=camera]').focus()
        zoomEnd(null)
        cacheStats()

  @instance: () ->
    @_SINGLETON

  @storageController: () ->
    Main._STORAGE_CONTROLLER

  @mapControl: () ->
    Main._MAP_CONTROL

  @map: () ->
    Main._MAP_CONTROL.map()

  @markerManager: () ->
    Main._MARKER_MANAGER
