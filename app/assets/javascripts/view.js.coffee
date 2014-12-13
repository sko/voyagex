class window.VoyageX.View

  @_SINGLETON = null

  constructor: () ->
    View._SINGLETON = this
    @_commListeners = {}
    for channel in ['talk', 'map_events', 'uploads']
      @_commListeners[channel] = []

  _systemCB: (message) ->
    console.log 'got a system - message: ' + message.type
    if message.type == 'ready_notification'
    else if message.type == 'subscription_grant_request'
      tr_template = $('#want_to_follow_me_template').html().
                    replace(/\{id\}/g, message.peer.id).
                    replace(/\{username\}/g, message.peer.username)
      $('#want_to_follow_me').append(tr_template)
    else if message.type == 'subscription_granted'
      $('#i_want_to_follow_'+message.peer.comm_setting_id).remove()
      tr_template = $('#i_follow_template').html().
                    replace(/\{id\}/g, message.peer.comm_setting_id).
                    replace(/\{username\}/g, message.peer.username)
      $('#i_follow').append(tr_template)
    else if message.type == 'subscription_denied'
      $('#i_want_to_follow_'+message.peer.comm_setting_id).remove()
      tr_template = $('#i_dont_follow_template').html().
                    replace(/\{id\}/g, message.peer.comm_setting_id).
                    replace(/\{username\}/g, message.peer.username)
      $('#i_dont_follow').append(tr_template)
    else if message.type == 'subscription_grant_revoked'
      $('#i_follow_'+message.peer.comm_setting_id).remove()
      tr_template = $('#i_dont_follow_template').html().
                    replace(/\{id\}/g, message.peer.comm_setting_id).
                    replace(/\{username\}/g, message.peer.username)
      $('#i_dont_follow').append(tr_template)
    else if message.type == 'quit_subscription'
      $('#follow_me_'+message.peer.id).remove()

  _talkCB: (message) ->
    console.log 'got a talk - message: ' + message.type
    if $('#current_user_id').val() == message.userId
      return null
    $('#message').val('\n-------------------------\n'+message.text+$('#message').val())
    $('#message').selectRange(0) 
    for listener in View.instance()._commListeners.talk
      listener(message)

  _mapEventsCB: (mapEvent) ->
    console.log 'got a map_events - message: ' + mapEvent.type
    if $('#current_user_id').val() == mapEvent.userId# && mapEvent.type == 'click'
      return null
    if VoyageX.Main.markerManager().get().getPopup()?
      VoyageX.Main.markerManager().get().unbindPopup()
    if mapEvent.address?
      setSelectedPositionLatLng VoyageX.Main.markerManager().get(), mapEvent.lat, mapEvent.lng, mapEvent.address
    else
      setSelectedPositionLatLng VoyageX.Main.markerManager().get(), mapEvent.lat, mapEvent.lng, null
    VoyageX.Main.map().panTo([mapEvent.lat, mapEvent.lng])
    #VoyageX.Main.map().setView [mapEvent.lat, mapEvent.lng], 16
    for listener in View.instance()._commListeners.map_events
      listener(mapEvent)

  _uploadsCB: (upload) ->
    console.log 'got an uploads - message: ' + upload.type
    maxHeight = 100
    scale = maxHeight / upload.file.height
    width = Math.round(upload.file.width * scale)
    style = 'width:'+width+'px;'
    if upload.file.type == 'image'
     #tag = '<span class="swiper-slide" onclick="panPosition('+upload.location.lat+','+upload.location.lng+',\''+upload.location.address+'\','+upload.file.id+')">'+
      tag = '<span class="swiper-slide" onclick="panUpload('+upload.id+')">'+
            '<img src="'+upload.file.url+'" style="'+style+'">'+
            '</span>'
    $("#upload_preview").prepend(tag)
    mySwiper.reInit()
    #mySwiper.resizeFix()
    for listener in View.instance()._commListeners.uploads
      listener(upload)
    if window.isMobile()
      $('a[href=#photo_nav_panel]').click()
    else
      $('#photo_nav_panel').dialog('open')
      if ! $('#photo_nav_panel').parent().hasClass('seethrough_panel')
        $('#photo_nav_panel').parent().addClass('seethrough_panel')

  addListener: (channel, callBack) ->
    @_commListeners[channel].push(callBack)

  @instance: () ->
    @_SINGLETON
