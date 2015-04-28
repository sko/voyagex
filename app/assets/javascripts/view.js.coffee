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
      View._SINGLETON.updateWantsToFollowMe message.peer
    else if message.type == 'subscription_granted'
      View._SINGLETON.updateIWantToFollow message.peer
    else if message.type == 'subscription_denied'
      View._SINGLETON.updateIWantToFollow message.peer, {denied: true}
    else if message.type == 'subscription_grant_revoked'
      View._SINGLETON.updateIFollow message.peer
    else if message.type == 'quit_subscription'
      View._SINGLETON.removeFollowsMe message.peer
    else if message.type == 'cancel_subscription_grant_request'
      APP.view().updateFollowsMe message.peer, {denied: true}

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

  # clearFollows: () ->
  #   $('#i_follow').html('')
  #   $('#i_want_to_follow').html('')
  #   $('#i_dont_follow').html('')
  #   $('#follow_me').html('')
  #   $('#want_to_follow_me').html('')

  setupForCurrentUser: () ->
    curU = APP.user()
    auth_whoami_html = $('#tmpl_auth_whoami').html().
                       replace(/:username/, curU.username)
    $('#whoami_img_nedit').html(auth_whoami_html)
    whoami_edit_html = $('#tmpl_whoami_edit').html().
                       replace(/\{auth_whoami\}/, auth_whoami_html)
    $('#whoami_edit').html(whoami_edit_html)
    
    auth_whoami_img_html = VoyageX.TemplateHelper._updateAttributes('tmpl_auth_whoami_img', ['src']).
                           replace(/\{foto_url\}/, curU.foto.url)
    $('#whoami_img_edit').html(auth_whoami_img_html)
    whoami_img_edit_html = $('#tmpl_whoami_img_edit').html().
                           replace(/\{auth_whoami_img\}/, auth_whoami_img_html)
    $('#whoami_img_nedit').html(whoami_img_edit_html)

    myfoto_html = VoyageX.TemplateHelper._updateAttributes('tmpl_myfoto', ['src']).
                  replace(/\{foto_url\}/, curU.foto.url)
    $('.myfoto').html(myfoto_html)

  addIFollow: (peer) ->
    tr_template = $('#i_follow_template').html().
                  replace(/\{id\}/g, peer.id).
                  replace(/\{channel_enc_key\}/, peer.peerPort.channel_enc_key).
                  replace(/\{username\}/g, peer.username).
                  replace(/tmpl-src/, 'src').
                  replace(/\{foto_url\}/, peer.foto.url)
    $('#i_follow').append(tr_template)
    # if window.isMobile()
    #   # required for applying layout and activating checkbox
    #   $('#comm_peer_data').trigger("create")

  addIWantToFollow: (peer) ->
    tr_template = $('#i_want_to_follow_template').html().
                  replace(/\{id\}/g, peer.id).
                  replace(/\{username\}/g, peer.username).
                  replace(/tmpl-src/, 'src').
                  replace(/\{foto_url\}/, peer.foto.url)
    $('#i_want_to_follow').append(tr_template)
    if window.isMobile()
      # required for applying layout and activating checkbox
      $('#comm_peer_data').trigger("create")

  addIDontFollow: (peer) ->
    tr_template = $('#i_dont_follow_template').html().
                  #replace(/\{id\}/g, peer.comm_port_id).
                  replace(/\{id\}/g, peer.id).
                  replace(/\{username\}/g, peer.username).
                  replace(/tmpl-src/, 'src').
                  replace(/\{foto_url\}/, peer.foto.url)
    $('#i_dont_follow').append(tr_template)
    if window.isMobile()
      # required for applying layout and activating checkbox
      $('#comm_peer_data').trigger("create")

  addFollowsMe: (peer) ->
    tr_template = $('#follows_me_template').html().
                  replace(/\{id\}/g, peer.id).
                  replace(/\{username\}/g, peer.username).
                  replace(/tmpl-src/, 'src').
                  replace(/\{foto_url\}/, peer.foto.url)
    $('#follow_me').append(tr_template)
    if window.isMobile()
      # required for applying layout and activating checkbox
      $('#comm_peer_data').trigger("create")

  addWantsToFollowMe: (peer) ->
    tr_template = $('#wants_to_follow_me_template').html().
                  replace(/\{id\}/g, peer.id).
                  replace(/\{username\}/g, peer.username).
                  replace(/tmpl-src/, 'src').
                  replace(/\{foto_url\}/, peer.foto.url)
    $('#want_to_follow_me').append(tr_template)
    if window.isMobile()
      # required for applying layout and activating checkbox
      $('#comm_peer_data').trigger("create")

  updateIFollow: (peer) ->
    $('#i_follow_'+peer.id).remove()
    if $('#i_dont_follow > #i_dont_follow_'+peer.id).length == 0
      View._SINGLETON.addIDontFollow peer
      if window.isMobile()
        $('#comm_peer_data').trigger("create")
  
  updateFollowsMe: (peer, flags = {granted: true}) ->
    $('#wants_to_follow_me_'+peer.id).remove()
    if flags.granted?
      View._SINGLETON.addFollowsMe peer
    if window.isMobile()
      $('#comm_peer_data').trigger("create")

  updateIDontFollow: (peer) ->
    View._SINGLETON.addIWantToFollow peer
    if window.isMobile()
      $('#comm_peer_data').trigger("create")

  updateIWantToFollow: (peer, flags = {granted: true}) ->
    $('#i_want_to_follow_'+peer.id).remove()
    if flags.granted?
      $('#i_dont_follow_'+peer.id).remove()
      View._SINGLETON.addIFollow peer
    else
      if $('#i_dont_follow > #i_dont_follow_'+peer.id).length == 0
        View._SINGLETON.addIDontFollow peer
    if window.isMobile()
      $('#comm_peer_data').trigger("create")

  updateWantsToFollowMe: (peer) ->
    View._SINGLETON.addWantsToFollowMe peer
    if window.isMobile()
      $('#comm_peer_data').trigger("create")
  
  removeFollowsMe: (peer) ->
    $('#follows_me_'+peer.id).remove()
    if window.isMobile()
      $('#comm_peer_data').trigger("create")

  setPeerPosition: (peerId, lat, lng) ->
    #TODO ... $('#people_of_interest')
    peer = APP.storage().getUser peerId
    path = APP.storage().getPath peer

    sBs = searchBounds lat, lng, APP.user().searchRadiusMeters
    curUserLatLng = APP.getSelectedPositionLatLng()
    if withinSearchBounds(curUserLatLng[0], curUserLatLng[1], sBs) || path?
      markerMeta = VoyageX.Main.markerManager().forPeer peerId
      markerMeta.m.setLocation {lat: lat, lng: lng}
      unless true || APP.view()._alertOn
        APP.view().alert()
    else
      console.log 'setPeerPosition: outside searchbounds ...'
      # remove from $('#people_of_interest')
      APP.markers().removeForPeer peerId

    if path? # leave separated from withinSearchBounds although it could go in block
      path = APP.storage().addToPath peer.id, {lat: lat, lng: lng}, path
      unless APP.smoothenPath peer, path
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

    target = $('.context_nav_open_icon')
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
        window.stopSound = VoyageX.MediaManager.instance().playSound(VoyageX.SOUNDS_ALERT_PATH, (event) ->
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
      window['myPoiSwiper'+poi.id].reInit()
    if window.isMobile()
      $('#open_context_nav_btn').click()
    else
      $('#context_nav_panel').dialog('open')
      if ! $('#context_nav_panel').parent().hasClass('seethrough_panel')
        $('#context_nav_panel').parent().addClass('seethrough_panel')
    # select initial tab
    $('#pois_preview_btn').click()

  previewBookmarks: () ->
    bookmarksPanel = $('#location_bookmarks')
    bookmarksPanel.find('.bookmark-container').remove()

    APP.storage().bookmarks (locations, bookmark, num, idx) ->
        bookmarksHTML = VoyageX.TemplateHelper.bookmarksHTML [bookmark]
        if idx >= 1
          bookmarksPanel.find('.bookmark-container').first().before(bookmarksHTML)
        else
          bookmarksPanel.find('table').first().append(bookmarksHTML)
        false

  previewUsers: () ->
    usersPanel = $('#people_of_interest')
    #usersPanel.find('table').html('')
    usersPanel.find('.user-container').remove()

    APP.storage().getPeers (userDB, peer, num, peerIdx) ->
        peerHTML = VoyageX.TemplateHelper.personOfInterestHTML [peer]
        usersPanel.find('table').first().append(peerHTML)
        false

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

  viewPoiNotes: (poi, poiNoteId, marker = null, resetTitle = false) ->
    VoyageX.TemplateHelper.openPOINotePopup poi, marker, resetTitle
    if poiNoteId >= 1
      APP.view().scrollToPoiNote poiNoteId
    bookmark = APP.storage().getBookmark(if poi.locationId? then poi.locationId else poi.location.id)
    if bookmark? && bookmark.text?
      $('#save-note').hide()
      $('#edit-note').show()
    else
      $('#save-note').show()
      $('#edit-note').hide()

  viewUserMarkerMenu: () ->
    marker = APP.markers().get()
#    address = null  
#    APP._setSelectedPositionLatLng marker, marker._latlng.lat, marker._latlng.lng, address
    VoyageX.TemplateHelper.openMarkerControlsPopup()
    location = APP.getUserMarker(true).m.location()
    bookmarkedLocation = APP.storage().getLocalLocation(location.lat, location.lng)
    if bookmarkedLocation?
      if bookmarkedLocation.bookmark? && bookmarkedLocation.bookmark.text?
        $('#save-note').hide()
        $('#edit-note').show()
      else
        $('#save-note').show()
        $('#edit-note').hide()

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
      msgDiv = $("div[class~=p2p_chat_msg]:not([class~='{toggle}'])").last()
    else
      msgDiv = $("div[class~=chat_message]:not([class~='{toggle}'])").last()
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
        msgHtml = VoyageX.TemplateHelper.p2PChatMsgHtml APP.user(), messageText
        peerChatMeta.chatContainer.find('.p2p_chat_view').first().append '<div class="chat_message_sep"></div>'+msgHtml
        #<div class="chat_message chat_message_'+meOrOther+' triangle-border '+leftOrRight+'">'+messageText+'</div>'
        msgInput = peerChatMeta.msgInput
      else
        VoyageX.TemplateHelper.openP2PChat peerChatMeta.peer, [messageText]
      APP.view().scrollToLastChatMessage peerChatMeta.peer, true
    else
      #$('.chat_view').append '<div class="chat_message_sep"></div><div class="chat_message chat_message_'+meOrOther+' triangle-border '+leftOrRight+'">'+messageText+'</div>'
      user = if mine then APP.user() else (if peerChatMeta? then peerChatMeta.peer else message.peer)
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
    console.log 'updatePoiNotes: TODO - rewrite ids, locationadress in popup and contextnav/swiper...'

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
    for listener in View.instance()._commListeners.pois
      listener(poi, newNotes)
    
    # add to popup
    VoyageX.TemplateHelper.addPoiNotes poi, newNotes, APP.getMarker(poi)
    View.instance().scrollToPoiNote newNotes[0].id
    #APP.panPosition(poi.lat, poi.lng, poi.address)

  @afterSyncPoiNotes: (poi, newNotes) ->
    console.log 'afterSyncPoiNotes: TODO: update data (address, id, ...)'

  @addBookmark: (bookmark) ->
    View.instance().viewBookmarkNote bookmark
    bookmarksPanel = $('#location_bookmarks')
    if bookmarksPanel.find('.bookmark-container[data-id='+bookmark.location.id+']').length == 0
      bookmarksHTML = VoyageX.TemplateHelper.bookmarksHTML [bookmark]
      bookmarkEntries = $('#location_bookmarks .bookmark-container')
      if bookmarkEntries.length >= 1
        $('#location_bookmarks .bookmark-container').first().before(bookmarksHTML)
      else
        $('#location_bookmarks table').first().append(bookmarksHTML)

  @editRadar: () ->
    VoyageX.TemplateHelper.openRadarEditor()

  @editTracePaths: (user) ->
    VoyageX.TemplateHelper.openTracePathEditor user

  @instance: () ->
    @_SINGLETON
