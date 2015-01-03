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

  _uploadsCB: (upload) ->
    console.log 'got an uploads - message: ' + upload.type
    unless upload.poi_note.user.id == APP.userId()
      window.stopSound = VoyageX.MediaManager.instance().playSound('/Treat.mp3')
      # TODO: unify json-format, until then avoid circular structure
      poi = upload.poi_note.poi
      msg = { poi: poi }
      Storage.Model.instance().syncWithStorage msg, View.addPoiNotes, upload.poi_note, 0

  previewPois: (pois) ->
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
    #poiId = $('#poi_notes_container > div[id^=upload_comment_btn_]').attr('id').match(/upload_comment_btn_([0-9]+)/)[1]
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

  @addPoiNotes: (poi) ->
    if poi.notes[0].attachment.content_type.match(/^[^\/]+/)[0] == 'image'
      mySwiper = window['myPoiSwiper'+poi.id]
      if mySwiper?
        swiperSlideHtml = VoyageX.TemplateHelper.swiperSlideHtml poi, poi.notes[0]
        $('#poi_swiper_'+poi.id+' .swiper-wrapper').prepend(swiperSlideHtml)
        mySwiper.reInit()
        #mySwiper.resizeFix()
    for listener in View.instance()._commListeners.uploads
      listener(poi.notes[0])

    VoyageX.TemplateHelper.addPoiNotes poi, APP.getMarker(poi)
    View.instance().scrollToPoiNote poi.notes[0].id
    #APP.panPosition(poi.lat, poi.lng, poi.address)

  @instance: () ->
    @_SINGLETON
