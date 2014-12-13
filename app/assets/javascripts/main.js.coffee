class window.VoyageX.Main
  
  @_SINGLETON = null
  @_STORAGE_CONTROLLER = null
  @_MAP_CONTROL = null
  @_MARKER_MANAGER = null
  @_COMM_CHANNELS = ['system', 'talk', 'map_events', 'uploads']

  constructor: (userId, cacheStrategy, view, mapOptions, offlineZooms, online) ->
    Main._SINGLETON = this
    @_initState = 0
    @_view = view
    $(window.document).ready () ->
        Main.instance()._init userId, cacheStrategy, view, mapOptions, offlineZooms, online

  _init: (userId, cacheStrategy, view, mapOptions, offlineZooms, online) ->
    Main.instance()._initState += 1
    switch Main.instance()._initState
      when 1
        Main._STORAGE_CONTROLLER = new Comm.StorageController((initError) ->
            console.log 'StorageController initialized FileSystem with message: '+(if initError then 'FAILED' else 'OK')
            #if error
            #else
            Main.instance()._init userId, cacheStrategy, view, mapOptions, offlineZooms, online
          )
        comm = new Comm.Comm(userId,
                             [['/talk', view._talkCB, window.VoyageX.CHANNEL_ENC_KEY],
                              ['/map_events', view._mapEventsCB, window.VoyageX.CHANNEL_ENC_KEY],
                              ['/uploads', view._uploadsCB, window.VoyageX.CHANNEL_ENC_KEY]],
                             window.VoyageX.SYS_CHANNEL_ENC_KEY,
                             this._systemCB)
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

  _systemCB: (message) ->
    console.log 'got a system - message: ' + message.type
    if message.type == 'ready_notification'
      # subscribe to all channels stored in window.subscribeTo-buffer
      while (channelPath = window.subscribeTo.pop())
        i = channelPath.indexOf(VoyageX.PEER_CHANNEL_PREFIX)
        channel = (if i == -1 then channelPath else channelPath.substr(0, i)).substr(1)
        Comm.Comm.subscribeTo channelPath, Comm.Comm.channelCallBacksJSON[channel].callback # eval(channel+'CB')
    else if message.type == 'subscription_grant_request'
    else if message.type == 'subscription_granted'
      for channel in VoyageX.Main.instance().commChannels()
        if channel == 'system'
          continue
        channelPath = '/'+channel
        unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
          channelPath += VoyageX.PEER_CHANNEL_PREFIX+message.peer.channel_enc_key
        Comm.Comm.subscribeTo channelPath, Comm.Comm.channelCallBacksJSON[channel].callback # eval(channel+'CB')
    else if message.type == 'subscription_denied'
    else if message.type == 'subscription_grant_revoked'
      for channel in VoyageX.Main.instance().commChannels()
        if channel == 'system'
          continue
        channelPath = '/'+channel
        unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
          channelPath += VoyageX.PEER_CHANNEL_PREFIX+message.peer.channel_enc_key
        Comm.Comm.unsubscribeFrom channelPath
    else if message.type == 'quit_subscription'
      true # do nothing
    Main.instance()._view._systemCB message

  @instance: () ->
    Main._SINGLETON

  @commChannels: () ->
    Main._COMM_CHANNELS.slice(0)

  @storageController: () ->
    Main._STORAGE_CONTROLLER

  @mapControl: () ->
    Main._MAP_CONTROL

  @map: () ->
    Main._MAP_CONTROL.map()

  @markerManager: () ->
    Main._MARKER_MANAGER
