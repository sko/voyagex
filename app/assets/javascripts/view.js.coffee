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
      #unless poi.notes?
      #  poi.notes = [note]
      #poiClone = eval("("+JSON.stringify(poi)+")")
      #delete upload.poi_note.poi
      #poi.notes = [eval("("+JSON.stringify(upload.poi_note)+")")]
      #poi.notes[0].poi = poiClone
      #upload.poi_note.poi = poi
      #msg = { poi: upload.poi_note.poi }
      ##poi = eval("("+JSON.stringify(upload.poi_note.poi)+")")
      ##poi.notes = [upload.poi_note]
      ##upload.poiNote.poi.notes = [eval("("+JSON.stringify(upload.poiNote)+")")]
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
    #
    if window.isMobile()
#      #if $('#upload_comment_conrols').hasClass('ui-popup-active')
#      #  $('#upload_comment_conrols').removeClass('ui-popup-active').addClass('ui-popup-hidden')
#      $('#upload_comment_cancel').click()
      $("#upload_data_panel").panel("close");
    else
      uploadDataDialog.dialog('close')
      #uploadCommentDialog.dialog('close')
    # ??? $('#poi_note_input').html('')

    unless poi.notes[0].poi?
      poi.notes[0].poi = poi
    #else
    #  $('#photo_nav_panel').dialog('open')
    #  if ! $('#photo_nav_panel').parent().hasClass('seethrough_panel')
    #    $('#photo_nav_panel').parent().addClass('seethrough_panel')

    popup = VoyageX.Main.markerManager().get().getPopup()
    if popup?
      i = $('.leaflet-popup .upload_comment').length
      popupEntryHtml = VoyageX.TemplateHelper.poiNotePopupHtmlFromTmpl(poi.notes[0], i)
      #$('.leaflet-popup .upload_comment').last().after(popupEntryHtml)
      #popup.update()
      #popupHtml = $('#poi_notes_container').parent().html().replace(/(<div[^>].+?upload_comment_btn_)/, popupEntryHtml+'$1')
      popupHtml = popup.getContent().replace(/(<div[^>].+?upload_comment_btn_)/, popupEntryHtml+'$1')
      $('#poi_notes_container').parent().html('')
      popup.setContent(popupHtml)
      popup.update()
      #$('#upload_comment_btn_'+poi.notes[0].id).on 'click', (event) ->
      #  openUploadCommentControls(poi.notes[0].id)
    else
      VoyageX.TemplateHelper.openPOINotePopup poi
      # @see TemplateHelper - openPOINotePopup for the following logic. it's also called from Model
      #$('.leaflet-popup-close-button').on 'click', (event) ->
      #    VoyageX.Main.markerManager().get().unbindPopup()
      #    $('.leaflet-popup').remove()
      #$('#upload_comment_btn_'+poiNote.id).on 'click', (event) ->
      #    openUploadCommentControls(poiNote.id);
      #    #$('#upload_comment_conrols').dialog('open')
      #    #if ! $('#upload_comment_conrols').parent().hasClass('seethrough_panel')
      #    #  $('#upload_comment_conrols').parent().addClass('seethrough_panel')

  @instance: () ->
    @_SINGLETON
