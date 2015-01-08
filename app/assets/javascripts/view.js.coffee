class window.VoyageX.View

  @_SINGLETON = null

  constructor: () ->
    View._SINGLETON = this
    @_commListeners = {}
    @_blinkArrowTO = null
    @_blink = false
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
    View.addChatMessage message, false
    for listener in View.instance()._commListeners.talk
      listener(message)

  _mapEventsCB: (mapEvent) ->
    console.log 'got a map_events - message: ' + mapEvent.type
    if APP.userId() == mapEvent.userId# && mapEvent.type == 'click'
      window.currentAddress = mapEvent.address
      $('#current_address').html(mapEvent.address+(if mapEvent.locationId? then ' ('+mapEvent.locationId+')' else ''))
      return null
#    if VoyageX.Main.markerManager().get().getPopup()?
#      VoyageX.Main.markerManager().get().unbindPopup()
    if mapEvent.address?
      APP._setSelectedPositionLatLng VoyageX.Main.markerManager().get(), mapEvent.lat, mapEvent.lng, mapEvent.address
    else
      APP._setSelectedPositionLatLng VoyageX.Main.markerManager().get(), mapEvent.lat, mapEvent.lng, null
    APP.map().panTo([mapEvent.lat, mapEvent.lng])
    #APP.map().setView [mapEvent.lat, mapEvent.lng], 16
    for listener in View.instance()._commListeners.map_events
      listener(mapEvent)
    APP.view().alert()

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
      @_blink = false
      clearTimeout @_blinkArrowTO
      target.each () ->
        $(this).attr('src', $(this).attr('src').replace(/(\.[^.]+|).png/, iconSuffix+'.png'))
      return true
    if @_blink
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
      @_blink = true
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
  
  viewBookmarkNote: (bookmark) ->
    VoyageX.TemplateHelper.openNoteEditor bookmark

  scrollToLastChatMessage: () ->
    msgDiv = $('.chat_message').last()
    msgDivOff = msgDiv.offset()
    if msgDivOff?
      scrollPane = msgDiv.closest('.chat_view').first()
      scrollPane.scrollTop(msgDivOff.top)

  @addChatMessage: (message, mine = true) ->
    if mine
      meOrOther = 'me'
      leftOrRight = 'left'
      #left = 0
      #$('.chat_view').append '<div>&nbsp;</div>'
    else
      meOrOther = 'other'
      leftOrRight = 'right'
      #left = Math.round($('.chat_view').width()*0.2)
    #$('.chat_view').append '<div style="left:'+left+'px;" class="chat_message chat_message_'+meOrOther+' triangle-border '+leftOrRight+'">'+message.text+'</div>'
    $('.chat_view').append '<div class="chat_message_sep"></div><div class="chat_message chat_message_'+meOrOther+' triangle-border '+leftOrRight+'">'+message.text+'</div>'
    APP.view().scrollToLastChatMessage()
    #$('#message').val('\n-------------------------\n'+message.text+$('#message').val())
    if mine
      $('#message').val('')
      if window.isMobile()
        $('#message').blur()
        $('body').scrollTop 0
      else
        $('#message').selectRange(0)

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
