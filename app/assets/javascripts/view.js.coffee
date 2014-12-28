class window.VoyageX.View

  @_SINGLETON = null

  constructor: () ->
    View._SINGLETON = this
    @_commListeners = {}
    for channel in ['talk', 'map_events', 'uploads']
      @_commListeners[channel] = []

  addListener: (channel, callBack) ->
    @_commListeners[channel].push(callBack)

  _systemCB: (message) ->
    console.log 'got a system - message: ' + message.type
    if message.type == 'ready_notification'
    else if message.type == 'subscription_grant_request'
      tr_template = $('#want_to_follow_me_template').html().
                    replace(/\{id\}/g, message.peer.id).
                    replace(/\{username\}/g, message.peer.username)
      $('#want_to_follow_me').append(tr_template)
      if window.isMobile()
        $('#comm_peer_data').trigger("create")
    else if message.type == 'subscription_granted'
      $('#i_want_to_follow_'+message.peer.comm_setting_id).remove()
      tr_template = $('#i_follow_template').html().
                    replace(/\{id\}/g, message.peer.comm_setting_id).
                    replace(/\{username\}/g, message.peer.username)
      $('#i_follow').append(tr_template)
      if window.isMobile()
        $('#comm_peer_data').trigger("create")
    else if message.type == 'subscription_denied'
      $('#i_want_to_follow_'+message.peer.comm_setting_id).remove()
      tr_template = $('#i_dont_follow_template').html().
                    replace(/\{id\}/g, message.peer.comm_setting_id).
                    replace(/\{username\}/g, message.peer.username)
      $('#i_dont_follow').append(tr_template)
      if window.isMobile()
        $('#comm_peer_data').trigger("create")
    else if message.type == 'subscription_grant_revoked'
      $('#i_follow_'+message.peer.comm_setting_id).remove()
      if $('#i_dont_follow > #i_dont_follow_'+message.peer.id).length == 0
        tr_template = $('#i_dont_follow_template').html().
                      replace(/\{id\}/g, message.peer.comm_setting_id).
                      replace(/\{username\}/g, message.peer.username)
        $('#i_dont_follow').append(tr_template)
        if window.isMobile()
          $('#comm_peer_data').trigger("create")
    else if message.type == 'quit_subscription'
      $('#follow_me_'+message.peer.id).remove()

  _talkCB: (message) ->
    console.log 'got a talk - message: ' + message.type
    if APP.userId() == message.userId
      return null
    $('#message').val('\n-------------------------\n'+message.text+$('#message').val())
    $('#message').selectRange(0) 
    for listener in View.instance()._commListeners.talk
      listener(message)

  _mapEventsCB: (mapEvent) ->
    console.log 'got a map_events - message: ' + mapEvent.type
    if APP.userId() == mapEvent.userId# && mapEvent.type == 'click'
      return null
    if VoyageX.Main.markerManager().get().getPopup()?
      VoyageX.Main.markerManager().get().unbindPopup()
    if mapEvent.address?
      APP._setSelectedPositionLatLng VoyageX.Main.markerManager().get(), mapEvent.lat, mapEvent.lng, mapEvent.address
    else
      APP._setSelectedPositionLatLng VoyageX.Main.markerManager().get(), mapEvent.lat, mapEvent.lng, null
    APP.map().panTo([mapEvent.lat, mapEvent.lng])
    #APP.map().setView [mapEvent.lat, mapEvent.lng], 16
    for listener in View.instance()._commListeners.map_events
      listener(mapEvent)

  _uploadsCB: (upload) ->
    console.log 'got an uploads - message: ' + upload.type
    unless upload.poi_note.user.id == APP.userId()
      window.stopSound = VoyageX.MediaManager.instance().playSound('/Treat.mp3')
      # TODO: unify json-format, until then avoid circular structure
      poi = upload.poi_note.poi
      msg = { poi: poi }
      Storage.Model._syncWithStorage msg, View.addPoiNotes, upload.poi_note, 0

  @addPoiNotes: (poi) ->
    if poi.notes[0].attachment.content_type.match(/^[^\/]+/)[0] == 'image'
      swiperSlideHtml = VoyageX.TemplateHelper.swiperSlideHtml poi.notes[0]
    $("#upload_preview").prepend(swiperSlideHtml)
    mySwiper.reInit()
    #mySwiper.resizeFix()
    for listener in View.instance()._commListeners.uploads
      listener(poi.notes[0])

    #
    # TODO: close uploads - this should go to the user who uploaded - not as a callback via faye
    #                       though lots of logic is the same
    #if window.isMobile()
    #  $("#upload_data_panel").panel("close");
    #else
    #  uploadDataDialog.dialog('close')

    VoyageX.TemplateHelper.addPoiNotes poi, APP.getMarker(poi)
    #APP.panPosition(poi.lat, poi.lng, poi.address)

  @instance: () ->
    @_SINGLETON
