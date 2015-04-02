class window.VoyageX.View

  @_SINGLETON = null
  
  @MAX_SWIPER_SLIDE_WIDTH = 300
  @MAX_SWIPER_SLIDE_HEIGHT = 100.0
  @MAX_POI_NOTE_ATTACHMENT_WIDTH = 300
  @MAX_POI_NOTE_ATTACHMENT_HEIGHT = 100.0

  constructor: () ->
    View._SINGLETON = this
    @_commListeners = {}
    @_blinkArrowTO = null
    @_alertOn = false
    for channel in VoyageX.Main._COMM_CHANNELS.slice(1)
      @_commListeners[channel] = []

  addListener: (channel, callBack) ->
    @_commListeners[channel].push(callBack)

  _systemCB: (message) ->
    #console.log 'got a system - message: ' + message.type
    if message.type == 'ready_notification'
    else if message.type == 'subscription_grant_request'
      tr_template = $('#want_to_follow_me_template').html().
                    replace(/\{id\}/g, message.peer.id).
                    replace(/\{username\}/g, message.peer.username).
                    replace(/tmpl-src/, 'src').
                    replace(/\{foto_url\}/, message.peer.foto.url)
      $('#want_to_follow_me').append(tr_template)
      if window.isMobile()
        $('#comm_peer_data').trigger("create")
    else if message.type == 'subscription_granted'
      $('#i_want_to_follow_'+message.peer.comm_port_id).remove()
      tr_template = $('#i_follow_template').html().
                    replace(/\{id\}/g, message.peer.comm_port_id).
                    replace(/\{channel_enc_key\}/, message.peer.channel_enc_key).
                    replace(/\{username\}/g, message.peer.username).
                    replace(/tmpl-src/, 'src').
                    replace(/\{foto_url\}/, message.peer.foto.url)
      $('#i_follow').append(tr_template)
      if window.isMobile()
        $('#comm_peer_data').trigger("create")
    else if message.type == 'subscription_denied'
      $('#i_want_to_follow_'+message.peer.comm_port_id).remove()
      tr_template = $('#i_dont_follow_template').html().
                    replace(/\{id\}/g, message.peer.comm_port_id).
                    replace(/\{username\}/g, message.peer.username).
                    replace(/tmpl-src/, 'src').
                    replace(/\{foto_url\}/, message.peer.foto.url)
      $('#i_dont_follow').append(tr_template)
      if window.isMobile()
        $('#comm_peer_data').trigger("create")
    else if message.type == 'subscription_grant_revoked'
      $('#i_follow_'+message.peer.comm_port_id).remove()
      if $('#i_dont_follow > #i_dont_follow_'+message.peer.id).length == 0
        tr_template = $('#i_dont_follow_template').html().
                      replace(/\{id\}/g, message.peer.comm_port_id).
                      replace(/\{username\}/g, message.peer.username).
                      replace(/tmpl-src/, 'src').
                      replace(/\{foto_url\}/, message.peer.foto.url)
        $('#i_dont_follow').append(tr_template)
        if window.isMobile()
          $('#comm_peer_data').trigger("create")
    else if message.type == 'quit_subscription'
      $('#follow_me_'+message.peer.id).remove()
    # else if message.type == 'callback'
    #   if message.channel == 'uploads'
    #     delete message.channel
    #     #message.type = message.action
    #     #delete message.action
    #     this._uploadsCB message

  _talkCB: (message) ->
    console.log 'got a talk - message: ' + message.type
    if APP.userId() == message.userId
      return null
    switch message.type
      when 'message'
        View.addChatMessage message, false
      when 'p2p-message'
        View.addChatMessage message, false, {peer: message.peer}
    for listener in View.instance()._commListeners.talk
      listener(message)

  _radarCB: (radarEvent) ->
    #
    # draw path modus -> no positionieg
    #
    console.log 'got a radar - message: ' + radarEvent.type
    if APP.userId() == radarEvent.userId# && radarEvent.type == 'move'
      return null
    View.instance().setPeerPosition radarEvent.userId, radarEvent.lat, radarEvent.lng
    for listener in View.instance()._commListeners.radar
      listener(radarEvent)

  _mapEventsCB: (mapEvent) ->
    console.log '_mapEventsCB: got a map_events - message: ' + mapEvent.type
    if APP.userId() == mapEvent.userId# && mapEvent.type == 'click'
      window.currentAddress = mapEvent.address
      $('#current_address').html(mapEvent.address+(if mapEvent.locationId? then ' ('+mapEvent.locationId+')' else ''))
      return null
    if false # move to event-ordinates
      if mapEvent.address?
        APP._setSelectedPositionLatLng VoyageX.Main.markerManager().get(), mapEvent.lat, mapEvent.lng, mapEvent.address
      else
        APP._setSelectedPositionLatLng VoyageX.Main.markerManager().get(), mapEvent.lat, mapEvent.lng, null
      APP.map().panTo([mapEvent.lat, mapEvent.lng])
      #APP.map().setView [mapEvent.lat, mapEvent.lng], 16
    #poiId ... $('#pois_preview > .poi-preview-container[data-id=68]')
    #locationId ... $('#location_bookmarks .bookmark-container[data-id=4016]')
    View.instance().setPeerPosition mapEvent.userId, mapEvent.lat, mapEvent.lng
    for listener in View.instance()._commListeners.map_events
      listener(mapEvent)

  # _uploadsCB: (upload) ->
  #   console.log 'got an uploads - message: ' + upload.type
  #   if upload.type == 'callback'
  #     # async backend response
  #     if upload.action? && upload.action == 'poi_sync'
  #       # assume that sync already performed with backend-response - here we hava after-commit-faye-callback
  #       currentUser.curCommitHash = upload.commit_hash
  #       #qPoiId = if upload.poi.local_time_secs? then -upload.poi.local_time_secs else upload.poi.id
  #       storedPoi = APP.storage().getPoi upload.poi.id
  #       callback = ((oldNotes) ->
  #           (cbPoi, cbNewNotes) ->
  #               #  
  #               # there could also be some new pois from other users! order might be mixed
  #               #
  #               location = APP.storage().getLocation(cbPoi.locationId)
  #               newNotes = oldNotes.slice 0, oldNotes.length-cbNewNotes.length
  #               for note, idx in cbNewNotes
  #                 newNotes.push note
  #                 if note.user?
  #                   note.userId = note.user.id
  #                   delete note.user
  #                 delete note.local_time_secs
  #               cbPoi.notes = newNotes
  #               VoyageX.TemplateHelper.openPOINotePopup cbPoi, null, true
  #               APP.view().scrollToPoiNote cbNewNotes[cbNewNotes.length-1].id
  #           )(storedPoi.notes)
  #       # save attachments from new other user's notes
  #       loadStats = { numAdded: upload.poi.notes.length, numLeft: upload.poi.notes.length }
  #       for note in upload.poi.notes
  #         Storage.Model.instance().syncWithStorage upload, callback, note, loadStats, note.local_time_secs?
  #   else if upload.type == 'poi_note_upload'
  #     unless upload.poi_note.user.id == APP.userId()
  #       # TODO: unify json-format, until then avoid circular structure
  #       poi = upload.poi_note.poi
  #       Storage.Model.setupPoiForNote poi
  #       msg = { poi: poi }
  #       Storage.Model.instance().syncWithStorage msg, View.addPoiNotes, upload.poi_note
  #       APP.view().alert()
  #   else if upload.type == 'poi_sync'
  #     if upload.poi.user.id != APP.userId()
  #       delete upload.poi.user
  #       poi = upload.poi
  #       Storage.Model.setupPoiForNote poi
  #       msg = { poi: poi }
  #       loadStats = { numAdded: poi.notes.length, numLeft: poi.notes.length }
  #       for note in poi.notes
  #         Storage.Model.instance().syncWithStorage msg, View.addPoiNotes, note, loadStats
  #       APP.view().alert()

  setPeerPosition: (userId, lat, lng) ->
    #TODO ... $('#people_of_interest')
    sBs = searchBounds lat, lng, VoyageX.SEARCH_RADIUS_METERS
    curUserLatLng = APP.getSelectedPositionLatLng()
    if withinSearchBounds curUserLatLng[0], curUserLatLng[1], sBs
      markerMeta = VoyageX.Main.markerManager().forPeer userId
      markerMeta.m.setLocation {lat: lat, lng: lng}
      unless true || APP.view()._alertOn
        APP.view().alert()
    else
      console.log '_mapEventsCB: outside searchbounds ...'
    peer = APP.storage().getUser userId
    path = APP.storage().getPath peer
    if path?
      path = APP.storage().addToPath peer, {lat: lat, lng: lng}, path
      VoyageX.Main.mapControl().drawPath peer, path, true

  setTraceCtrlIcon: (user, marker, state) ->
    if state == 'start'
      $('#trace-ctrl-start-'+user.id).css('display', 'none')
      $('#trace-ctrl-stop-'+user.id).css('display', 'inline')
    else
      $('#trace-ctrl-start-'+user.id).css('display', 'inline')
      $('#trace-ctrl-stop-'+user.id).css('display', 'none')

  setRealPositionWatchedIcon: (state) ->
    if state == 'on'
      $('#toggle_watch_position_off').css('display', 'none')
      $('#toggle_watch_position_on').css('display', 'inline')
    else
      $('#toggle_watch_position_off').css('display', 'inline')
      $('#toggle_watch_position_on').css('display', 'none')

  # start with no params
  # assets-compile: arrow-up-right_on.png -> arrow-up-right_on-ea4366b17dad061ef49336a4ae3e90b4.png
  _blinkArrow: (setOn = true, stop = false) ->
    if setOn
      iconSuffix = '_on'
    else
      iconSuffix = '_off'

    target = $('.photo_nav_open_icon')
    if stop
      @_alertOn = false
      clearTimeout @_blinkArrowTO
      target.each () ->
        $(this).attr('src', VoyageX.IMAGES_CTXNAVALERT_OFF_PATH)
      return true
    if @_alertOn
      if setOn
        target.each () ->
          $(this).attr('src', VoyageX.IMAGES_CTXNAVALERT_ON_PATH)
        @_blinkArrowTO = setTimeout "APP.view()._blinkArrow(false)", 500
      else
        target.each () ->
          $(this).attr('src', VoyageX.IMAGES_CTXNAVALERT_OFF_PATH)
        @_blinkArrowTO = setTimeout "APP.view()._blinkArrow()", 500

  alert: (stop = false) ->
    if stop
      this._blinkArrow false, true
      window.stopSound = null
    else
      @_alertOn = true
      unless stopSound?
        window.stopSound = VoyageX.MediaManager.instance().playSound('/Treat.mp3', (event) ->
            if event.msg == 'finished'
              `;`#window.stopSound = null
          )
      this._blinkArrow()

  previewPois: (pois) ->
    this.alert true
    poisPreviewHtml = VoyageX.TemplateHelper.poisPreviewHTML pois
    $('#pois_preview').html(poisPreviewHtml)
    # this has to be done after html is added ...
    for poi in pois
      window['myPoiSwiper'+poi.id] = $('#poi_swiper_'+poi.id).swiper({
        createPagination: false,
        centeredSlides: true,
        slidesPerView: 'auto',
        onSlideClick: APP.swiperPhotoClicked
      })
    if window.isMobile()
      $('#open_photo_nav_btn').click()
    else
      $('#photo_nav_panel').dialog('open')
      if ! $('#photo_nav_panel').parent().hasClass('seethrough_panel')
        $('#photo_nav_panel').parent().addClass('seethrough_panel')
    # select initial tab
    $('#pois_preview_btn').click()

  viewAttachment: (poiNoteId) ->
    #poiId = $('#poi_notes_container').attr('data-poiId')
    imgUrl = $('#poi_notes_container .upload_comment[data-id='+poiNoteId+'] img').attr('src')
    #height = attachmentViewPanel.height()
    if window.isMobile()
      maxWidth = Math.abs($(window).width() * 0.8)-10
      maxHeight = Math.abs($(window).height() * 0.8)-10
      $('#attachment_view_panel').html($('#attachment_view_panel_close_btn').html()+'<div class="attachment_view"><img src="'+imgUrl+'" style="max-width:'+maxWidth+'px;max-height:'+maxHeight+'px;"></div>')
      $('#open_attachment_view_btn').click()
    else
      maxWidth = Math.abs($(window).width() * 0.5)-10
      maxHeight = Math.abs($(window).height() * 0.8)-10
      $('#attachment_view_panel').html('<div class="attachment_view"><img src="'+imgUrl+'" style="max-width:'+maxWidth+'px;max-height:'+maxHeight+'px;"></div>')
      $('#attachment_view_panel').dialog('open')
  
  # called for either poi- or user-marker
  viewBookmarkNote: (location) ->
    VoyageX.TemplateHelper.openNoteEditor location
  
  viewPeerNote: (peer) ->
    markerMeta = VoyageX.Main.markerManager().forPeer peer.id
    VoyageX.TemplateHelper.openPeerNoteEditor peer, markerMeta.target()

  viewTracePath: (user, pathKey) ->
    path = APP.storage().getPath user, pathKey, false
    VoyageX.Main.mapControl().drawPath user, path
    $('#hide_trace-path_'+pathKey).css 'display', 'inline'

  hideTracePath: (pathKey) ->
    VoyageX.Main.mapControl().hidePath pathKey
    $('#hide_trace-path_'+pathKey).css 'display', 'none'

  # started from peer-tool-bar
  openP2PChat: (peer) ->
    VoyageX.TemplateHelper.openP2PChat peer
    this.scrollToLastChatMessage peer, true

  scrollToLastChatMessage: (lastSender, isP2P = false) ->
    if isP2P
      scrollPane = $('#peer_popup_'+lastSender.id+' > .p2p_chat_container > .p2p_chat_view').first()
      msgDiv = $("div[class*='p2p_chat_msg']:not([class*=toggle])").last()
    else
      msgDiv = $("div[class*='chat_message']:not([class*=toggle])").last()
    msgDivOff = msgDiv.offset()
    if msgDivOff?
      unless scrollPane?
        scrollPane = msgDiv.closest('.chat_view').first()
      scrollPane.scrollTop(msgDivOff.top)

  @addChatMessage: (message, mine = true, peerChatMeta = null) ->
    if mine
      meOrOther = 'me'
      leftOrRight = 'left'
    else
      meOrOther = 'other'
      leftOrRight = 'right'
    messageText = message.text.replace(/\n/g, '<br/>')
    if peerChatMeta?
      if mine
        msgHtml = VoyageX.TemplateHelper.p2PChatMsgHtml currentUser, messageText
        peerChatMeta.chatContainer.find('.p2p_chat_view').first().append '<div class="chat_message_sep"></div>'+msgHtml
        #<div class="chat_message chat_message_'+meOrOther+' triangle-border '+leftOrRight+'">'+messageText+'</div>'
        msgInput = peerChatMeta.msgInput
      else
        VoyageX.TemplateHelper.openP2PChat peerChatMeta.peer, [messageText]
      APP.view().scrollToLastChatMessage peerChatMeta.peer, true
    else
      #$('.chat_view').append '<div class="chat_message_sep"></div><div class="chat_message chat_message_'+meOrOther+' triangle-border '+leftOrRight+'">'+messageText+'</div>'
      user = if mine then currentUser else (if peerChatMeta? then peerChatMeta.peer else message.peer)
      msgHtml = VoyageX.TemplateHelper.bcChatMsgHtml user, messageText, meOrOther
      $('.chat_view').append '<div class="chat_message_sep"></div>'+msgHtml
      msgInput = $('#message')
      APP.view().scrollToLastChatMessage user
    #msgInput.val('\n-------------------------\n'+messageText+msgInput.val())
    if mine
      msgInput.val('')
      if window.isMobile()
        msgInput.blur()
        $('body').scrollTop 0
      else
        msgInput.selectRange(0)

  scrollToPoiNote: (poiNoteId) ->
    poiNoteDiv = $('#poi_notes_container').children('[data-id='+poiNoteId+']').first()
    poiNoteOff = poiNoteDiv.offset()
    if poiNoteOff?
      scrollPane = poiNoteDiv.closest('.leaflet-popup-content').first()
      scrollPane.scrollTop(poiNoteOff.top)

  @updatePoiNotes: (poi, newNotes) ->
    console.log 'updatePoiNotes: TODO - rewrite ids, locationadress in popup and photonav/swiper...'

  @addPoiNotes: (poi, newNotes) ->
    #if poi.notes[0].attachment.content_type.match(/^[^\/]+/)[0] == 'image'
    mySwiper = window['myPoiSwiper'+poi.id]
    if mySwiper?
      swiperWrapper = $('#poi_swiper_'+poi.id+' .swiper-wrapper')
      for note, i in newNotes
        swiperSlideHtml = VoyageX.TemplateHelper.swiperSlideHtml poi, note
        swiperWrapper.append(swiperSlideHtml)
      #VoyageX.TemplateHelper.addPoiNotes poi, newNotes, APP.getMarker(poi)
      #View.instance().scrollToPoiNote newNotes[0].id
    else
      # most likely a new poi
      # create swiper
      poisPreviewHtml = VoyageX.TemplateHelper.poisPreviewHTML [poi]
      # TODO correct position
      $('#pois_preview').prepend(poisPreviewHtml)
      window['myPoiSwiper'+poi.id] = $('#poi_swiper_'+poi.id).swiper({
        createPagination: false,
        centeredSlides: true,
        slidesPerView: 'auto',
        onSlideClick: APP.swiperPhotoClicked
      })
      mySwiper = window['myPoiSwiper'+poi.id]
    mySwiper.reInit()
    #mySwiper.resizeFix()
    for listener in View.instance()._commListeners.uploads
      listener(poi, newNotes)
    
    # add to popup
    VoyageX.TemplateHelper.addPoiNotes poi, newNotes, APP.getMarker(poi)
    View.instance().scrollToPoiNote newNotes[0].id
    #APP.panPosition(poi.lat, poi.lng, poi.address)

  @afterSyncPoiNotes: (poi, newNotes) ->
    console.log 'afterSyncPoiNotes: TODO: update data (address, id, ...)'

  @addBookmark: (bookmarkLocation) ->
    View.instance().viewBookmarkNote bookmarkLocation
    bookmarksPanel = $('#location_bookmarks')
    if bookmarksPanel.find('.bookmark-container[data-id='+bookmarkLocation.id+']').length == 0
      locationsBookmarksHTML = VoyageX.TemplateHelper.locationsBookmarksHTML [bookmarkLocation]
      bookmarkEntries = $('#location_bookmarks .bookmark-container')
      if bookmarkEntries.length >= 1
        $('#location_bookmarks .bookmark-container').first().before(locationsBookmarksHTML)
      else
        $('#location_bookmarks table').first().append(locationsBookmarksHTML)

  @editRadar: () ->
    VoyageX.TemplateHelper.openRadarEditor()

  @editTracePaths: (user) ->
    VoyageX.TemplateHelper.openTracePathEditor user

  @instance: () ->
    @_SINGLETON
