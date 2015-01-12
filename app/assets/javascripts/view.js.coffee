class window.VoyageX.View

  @_SINGLETON = null

  constructor: () ->
    View._SINGLETON = this
    @_commListeners = {}
    @_blinkArrowTO = null
    @_alertOn = false
    for channel in ['talk', 'map_events', 'uploads']
      @_commListeners[channel] = []

  addListener: (channel, callBack) ->
    @_commListeners[channel].push(callBack)

  _systemCB: (message) ->
    #console.log 'got a system - message: ' + message.type
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
                    replace(/\{channel_enc_key\}/, message.peer.channel_enc_key).
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
    switch message.type
      when 'message'
        View.addChatMessage message, false
      when 'p2p-message'
        peer = Comm.StorageController.instance().getUser parseInt(message.userId)
        View.addChatMessage message, false, {peer: peer}
    for listener in View.instance()._commListeners.talk
      listener(message)

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
    #TODO ... $('#people_of_interest')
    sBs = searchBounds mapEvent.lat, mapEvent.lng, VoyageX.SEARCH_RADIUS_METERS
    curUserLatLng = APP.getSelectedPositionLatLng()
    if withinSearchBounds curUserLatLng[0], curUserLatLng[1], sBs
      markerMeta = VoyageX.Main.markerManager().forPeer mapEvent.userId
      markerMeta.target().setLatLng L.latLng(mapEvent.lat, mapEvent.lng)
      unless true || APP.view()._alertOn
        APP.view().alert()
    else
      console.log '_mapEventsCB: outside searchbounds ...'
    for listener in View.instance()._commListeners.map_events
      listener(mapEvent)

  _uploadsCB: (upload) ->
    console.log 'got an uploads - message: ' + upload.type
    unless upload.poi_note.user.id == APP.userId()
      # TODO: unify json-format, until then avoid circular structure
      poi = upload.poi_note.poi
      Storage.Model.setupPoiForNote poi
      msg = { poi: poi }
      Storage.Model.instance().syncWithStorage msg, View.addPoiNotes, upload.poi_note
      APP.view().alert()

  # start with no params
  _blinkArrow: (iconSuffix = null, stop = false) ->
    target = $('.photo_nav_open_icon')
    if stop
      @_alertOn = false
      clearTimeout @_blinkArrowTO
      target.each () ->
        $(this).attr('src', $(this).attr('src').replace(/(\.[^.]+|).png/, iconSuffix+'.png'))
      return true
    if @_alertOn
      if iconSuffix?
        target.each () ->
          $(this).attr('src', $(this).attr('src').replace(/(\.[^.]+|).png/, iconSuffix+'.png'))
        if iconSuffix == ''
          @_blinkArrowTO = setTimeout "APP.view()._blinkArrow()", 500
        else
          unless stopSound?
            window.stopSound = VoyageX.MediaManager.instance().playSound('/Treat.mp3', (event) ->
                if event.msg == 'finished'
                  `;`#window.stopSound = null
              )
      else
        this._blinkArrow '.on'
        @_blinkArrowTO = setTimeout "APP.view()._blinkArrow('')", 500

  alert: (stop = false) ->
    if stop
      this._blinkArrow '', true
      window.stopSound = null
    else
      @_alertOn = true
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
        onSlideClick: photoClicked
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
  viewBookmarkNote: (bookmark) ->
    VoyageX.TemplateHelper.openNoteEditor bookmark
  
  viewPeerNote: (peer) ->
    markerMeta = VoyageX.Main.markerManager().forPeer peer.id
    VoyageX.TemplateHelper.openPeerNoteEditor peer, markerMeta.target()

  scrollToLastChatMessage: (peerChatMeta = null) ->
    if peerChatMeta?
      scrollPane = $('#peer_popup_'+peerChatMeta.peer.id+' > .p2p_chat_container > .p2p_chat_view').first()
      msgDiv = scrollPane.find('.p2p_chat_msg').last()
    else
      msgDiv = $('.chat_message').last()
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
    if peerChatMeta?
      if mine
        msgHtml = VoyageX.TemplateHelper.p2PChatMsgHtml currentUser, message.text
        peerChatMeta.chatContainer.find('.p2p_chat_view').first().append '<div class="chat_message_sep"></div>'+msgHtml
        #<div class="chat_message chat_message_'+meOrOther+' triangle-border '+leftOrRight+'">'+message.text+'</div>'
        msgInput = peerChatMeta.msgInput
      else
        VoyageX.TemplateHelper.openP2PChat peerChatMeta.peer, [message.text]
    else
      $('.chat_view').append '<div class="chat_message_sep"></div><div class="chat_message chat_message_'+meOrOther+' triangle-border '+leftOrRight+'">'+message.text+'</div>'
      msgInput = $('#message')
    APP.view().scrollToLastChatMessage peerChatMeta
    #msgInput.val('\n-------------------------\n'+message.text+msgInput.val())
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

  @addPoiNotes: (poi, newNotes) ->
    if poi.notes[0].attachment.content_type.match(/^[^\/]+/)[0] == 'image'
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
          onSlideClick: photoClicked
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

  @addBookmark: (bookmark) ->
    View.instance().viewBookmarkNote bookmark
    bookmarksPanel = $('#location_bookmarks')
    if bookmarksPanel.find('.bookmark-container[data-id='+bookmark.location.id+']').length == 0
      locationsBookmarksHTML = VoyageX.TemplateHelper.locationsBookmarksHTML [bookmark]
      bookmarkEntries = $('#location_bookmarks .bookmark-container')
      if bookmarkEntries.length >= 1
        $('#location_bookmarks .bookmark-container').first().before(locationsBookmarksHTML)
      else
        $('#location_bookmarks table').first().append(locationsBookmarksHTML)

  @instance: () ->
    @_SINGLETON
