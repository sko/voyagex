class window.VoyageX.TemplateHelper
 
  @_SINGLETON = null

  @poiNoteInputHtml: (parentElementId, poi = null, poiNote = null) ->
    formId = null
    html = TemplateHelper._updateIds 'tmpl_poi_note_input', (cur) ->
        if cur.match(/_form$/) != null
          formId = cur
    html = TemplateHelper._updateRefs 'tmpl_poi_note_input', html.replace(/:poi_id/, if poi? then poi.id else -1)
    $('#'+parentElementId).html(html)
    if formId != null
      form = $('#'+formId)
      if poiNote != null 
        methodDiv = form.find('div').first()
        methodDiv.append('<input type="hidden" name="_method" value="put">')
        form.attr('action', updateActionPathTmpl.replace(/:comments_on_id/, poiNote.id))
        form.attr('data-commentsonid', poiNote.id)
      else
        form.attr('data-commentsonid', -1)

  @poiNotePopupHtmlFromTmpl: (poiNote, i, poi = null, meta = null) ->
    unless meta?
      meta = {height: 0}
    html = TemplateHelper._updateIds 'tmpl_poi_note'
    poiNotesHtml = TemplateHelper.poiNotePopupEntryHtml(poiNote, html, i, meta)
    if poi != null
      popupHtml = TemplateHelper._updateIds 'tmpl_poi_notes_container'
      popupHtml = popupHtml.
                  replace(/\{poi_notes\}/, poiNotesHtml).
                  replace(/\{poi_id\}/g, poiNote.poi.id)
    else
      poiNotesHtml

  @poiNotePopupEntryHtml: (poiNote, poiNoteTmpl, i, meta) ->
    if poiNote.user?
      username = poiNote.user.username
      isCurrentUserNote = poiNote.user.id==currentUser.id
    else
      username = Comm.StorageController.instance().getUser(poiNote.userId).username
      isCurrentUserNote = poiNote.userId==currentUser.id
    toggle = if isCurrentUserNote then 'left' else 'right'
    poiNoteTmpl.
    replace(/\{poi_note_id\}/g, poiNote.id).
    replace(/\{i\}/g, i).
    replace(/\{toggle\}/g, toggle).
    replace(/\stmpl-toggle=['"]?[^'" >]+/g, '').
    replace(/\{media_file_tag\}/, TemplateHelper._mediaFileTag(poiNote.attachment, meta)).
    replace(/\{username\}/, username).
    replace(/\{comment\}/, padTextHtml(poiNote.text, 80))

  @poiNotePopupHtml: (poi, meta) ->
    popupHtml = TemplateHelper._updateIds 'tmpl_poi_notes_container'
    poiNoteTmpl = TemplateHelper._updateIds 'tmpl_poi_note'
    poiNotesHtml = ''
    for poiNote, i in poi.notes
      poiNotesHtml += TemplateHelper.poiNotePopupEntryHtml(poiNote, poiNoteTmpl, i, meta)
    bookmark = APP.storage().getBookmark(poi.locationId)
    popupHtml = popupHtml.
                replace(/\{poi_id\}/g, poi.id).
                replace(/\{location_id\}/g, poi.locationId).
                replace(/\{display_view_note_btn\}/g, if bookmark? then 'inline' else 'none').
                #replace(/\{address\}/g, poi.address).
                replace(/\{poi_notes\}/, poiNotesHtml)

  @addPoiNotes: (poi, newNotes, marker) ->
    popup = marker.getPopup()
    if popup?
     #i = $('.leaflet-popup .upload_comment').length
      i = poi.notes.length - newNotes.length
      newPopupHtml = ''
      for note, j in newNotes
        newPopupHtml += TemplateHelper.poiNotePopupHtmlFromTmpl(note, i+j)
      popupHtml = popup.getContent().replace(/(<div[^>]* class=["'][^'"]*\s?poi_controls(["']|\s))/, newPopupHtml+'$1')
      popup.setContent(popupHtml)
      #$('#poi_notes_container div.upload_comment').last().prepend(newPopupHtml)
      #popup.update()
      unless popup._isOpen
        marker.openPopup()
        VoyageX.Main.markerManager().userMarkerMouseOver false
    else
      TemplateHelper.openPOINotePopup poi, marker

  @openPOINotePopup: (poi, marker = null, resetTitle = false) ->
    meta = {height: 0}
    popupHtml = TemplateHelper.poiNotePopupHtml(poi, meta)
    if marker == null
      marker = APP.getMarker poi
    popup = marker.getPopup()
    isNewPopup = !popup?
    if isNewPopup
      popup = L.popup {minWidth: 200, maxHeight: 300} #autoPan: false, 
      marker.bindPopup(popup)
      marker.off('click', marker.togglePopup, marker)
    popup.setContent(popupHtml)
    marker.openPopup()
    VoyageX.Main.markerManager().userMarkerMouseOver false
    if isNewPopup || resetTitle
      poiNoteContainer = $('#poi_notes_container')
      TemplateHelper._addPopupTitle poiNoteContainer, marker, Comm.StorageController.instance().getLocation(poi.locationId), poi, resetTitle
    $('#poi_note_input').html('')
    TemplateHelper.poiNoteInputHtml('poi_note_input', poi, poi.notes[0])

  @openPeerPopup: (peer, marker, messages = [], contentCallback = null) ->
    curPath = APP.storage().getPath peer
    popupHtml = TemplateHelper._updateAttributes('tmpl_peer_popup', ['src'], TemplateHelper._updateIds('tmpl_peer_popup')).
    replace(/\{peer_id\}/g, peer.id).
    replace(/\{peer_name\}/g, peer.username).
    replace(/\{peer_foto_url\}/, peer.foto.url).
    replace(/\{path_key\}/g, if curPath? then "'"+curPath[0].timestamp+"'" else 'null')
    popup = marker.getPopup()
    isNewPopup = !popup?
    if isNewPopup
      popup = L.popup()# {autoPan: false, minWidth: 200, maxHeight: 300}
      marker.bindPopup(popup)
      marker.off('click', marker.togglePopup, marker)
    popup.setContent(if contentCallback? then contentCallback(popupHtml, peer, marker, messages) else popupHtml)
    marker.openPopup()
    VoyageX.Main.markerManager().userMarkerMouseOver false
    if isNewPopup
      peerPopup = $('#peer_popup_'+peer.id)
      popupContainer = peerPopup.closest('.leaflet-popup').first()
      popupContainer.prepend('<span id="current_peer" style="float: left; padding-left: 5px; font-size: 9px;">'+peer.username+'</span>')
    APP.view().setTraceCtrlIcon peer, marker, if curPath? then 'start' else 'stop'

  @openMarkerControlsPopup: () ->
    marker = VoyageX.Main.markerManager().get()
    curPath = APP.storage().getPath currentUser
    popupHtml = TemplateHelper._updateIds('tmpl_marker_controls').
    replace(/\{user_id\}/g, currentUser.id).
    replace(/\{path_key\}/g, if curPath? then "'"+curPath[0].timestamp+"'" else 'null')
    popup = marker.getPopup()
    isNewPopup = !popup?
    if isNewPopup
      popup = L.popup(autoPan: false)
      marker.bindPopup popup
      marker.off('click', marker.togglePopup, marker)
    popup.setContent popupHtml
    marker.openPopup()
    if isNewPopup
      poiNoteContainer = $('#marker_controls')
      TemplateHelper._addPopupTitle poiNoteContainer, marker, {address: currentAddress}#Comm.StorageController.instance().getLocation(poi.locationId)
    else
      $('#current_address').html(currentAddress)
    APP.view().setTraceCtrlIcon currentUser, marker, if curPath? then 'start' else 'stop'

  @noteHtml: (typeId, text) ->
    TemplateHelper._updateIds('tmpl_note_editor').
    replace(/\{type\}_\{id\}/g, typeId).
    replace(/\{text\}/, text)

  @editorFor: (target, marker, typeId, callback) ->
    popup = marker.getPopup()
    # note-editor is within existing popup - user, poi or peer - so it should already exist here
    popupHtml = TemplateHelper._resetMarkerControlsPopup popup, 'note_editor'
#    popupHtml = popup.getContent()
#    if popupHtml.indexOf('radar_editor') != -1
#      #popupHtml = popupHtml.replace(/<div[^>]+class="radar_editor"(.|\n)+(<div[^>]+id="marker_controls")/, '$1')
#      popupHtml = popupHtml.replace(/<div[^>]+class="radar_editor"(.|\n)+/, '$1')
    editorHtml = callback target
    if popupHtml.indexOf('note_editor') == -1
      popup.setContent popupHtml + editorHtml
    marker.openPopup()
    noteEditor = $('#'+typeId).closest('.note_editor').first()
    noteEditor.closest('.leaflet-popup-content').first().scrollTop(noteEditor.offset().top)
    $('#'+typeId).focus()

  @openNoteEditor: (location) ->
    marker = APP.getOpenPopupMarker()
    unless marker?
      marker = VoyageX.Main.markerManager().get()
    TemplateHelper.editorFor location, marker, 'note_bookmark_'+location.id, (location) ->
        TemplateHelper.noteHtml 'bookmark_'+location.id, if location.bookmark? && location.bookmark.text? then location.bookmark.text else ''

  @openPeerNoteEditor: (peer, marker) ->
    TemplateHelper.editorFor peer, marker, 'note_peer_'+peer.id, (peer) ->
        TemplateHelper.noteHtml 'peer_'+peer.id, if peer.note? then peer.note else ''

  @p2PChatMsgHtml: (from, message, messageHtml = null) ->
    unless messageHtml?
      #messageHtml = $('#tmpl_p2p_chat_msg').html()
      messageHtml = TemplateHelper._updateAttributes('tmpl_p2p_chat_msg', ['src'])
    toggle = if from.id==currentUser.id then 'left' else 'right'
    messageHtml.
    replace(/\{toggle\}/, toggle).
    replace(/\stmpl-toggle=['"]?[^'" >]+/g, '').
    replace(/\{foto_url\}/, from.foto.url).
    replace(/\{message\}/, message)

  @p2PChatHtml: (peer, messages, p2pChatHtml = null) ->
    unless p2pChatHtml?
      p2pChatHtml = TemplateHelper._updateIds('tmpl_p2p_chat_container').
      replace(/\{peer_id\}/g, peer.id)
    #messageHtml = $('#tmpl_p2p_chat_msg').html()
    messageHtml = TemplateHelper._updateAttributes('tmpl_p2p_chat_msg', ['src'])
    #i = $('.leaflet-popup .p2p_chat_msg').length
    newMessagesHtml = ''
    for msg, j in messages
      newMessagesHtml += TemplateHelper.p2PChatMsgHtml(peer, msg, messageHtml)
    p2pChatHtml.
    replace(/(<\/div>\s*<div[^>]* class=['"]\s*p2p_chat_input\s*['"][^>]*>)/m, newMessagesHtml+'$1')

  @openP2PChat: (peer, newMessages = []) ->
    markerMeta = VoyageX.Main.markerManager().forPeer peer.id
    popup = markerMeta.target().getPopup()
    if popup?
      popupHtml = popup.getContent()
      # $('#peer_popup_196')
      # $('#peer_popup_196 > .p2p_chat_container > .p2p_chat_view > p2p_chat_msg')
      if popupHtml.indexOf('p2p_chat_container') == -1
        # maybe add-chat should go to APP (initChat())
        APP.initP2PChatMessages peer, newMessages
        p2pChatHtml = TemplateHelper.p2PChatHtml peer, newMessages
      else
        # chat opened - new messages from peer
        # only if popup is open
        #popupContainer = $('#peer_popup_'+peer.id)
        chatContainerContent = $('#peer_popup_'+peer.id+' > .p2p_chat_container').first().wrap('<p/>').parent().html()
        $('#peer_popup_'+peer.id+' > p > .p2p_chat_container').first().unwrap()
        p2pChatHtml = TemplateHelper.p2PChatHtml peer, newMessages, chatContainerContent
     #popupHtml = popupHtml.replace(/(<div[^>]* id=['"]peer_popup_'+peer.id+'['"][^>]*>)(.|[\r\n])+?(<div[^>]* class=['"]\s*p2p_controls\s*['"])/, '$1'+p2pChatHtml+'$3')
      containerRegexp = new RegExp('(<div[^>]* id=[\'"]peer_popup_'+peer.id+'[\'"][^>]*>)(.|[\\r\\n])+?(<div[^>]* class=[\'"]\\s*p2p_controls\\s*[\'"])')
      popupHtml = popupHtml.replace(containerRegexp, '$1'+p2pChatHtml+'$3')
      popup.setContent popupHtml
      # / if popupHtml.indexOf('p2p_chat_container') == -1
      markerMeta.target().openPopup()
    else
      TemplateHelper.openPeerPopup peer, markerMeta.target(), newMessages, (popupHtml, peer, marker, messages) ->
          if popupHtml.indexOf('p2p_chat_container') == -1
            p2pChatHtml = TemplateHelper.p2PChatHtml peer, messages
           #popupHtml = popupHtml.replace(/(<div[^>]* id=['"]peer_popup_'+peer.id+'['"][^>]*>)(.|[\r\n])+?(<div[^>]* class=['"]\s*p2p_controls\s*['"])/, '$1'+p2pChatHtml+'$3')
            containerRegexp = new RegExp('(<div[^>]* id=[\'"]peer_popup_'+peer.id+'[\'"][^>]*>)(.|[\\r\\n])+?(<div[^>]* class=[\'"]\\s*p2p_controls\\s*[\'"])')
            popupHtml = popupHtml.replace(containerRegexp, '$1'+p2pChatHtml+'$3')
          popupHtml
    APP.chat().addP2PMsgInput $('#p2p_message_'+peer.id)
    VoyageX.Main.markerManager().userMarkerMouseOver false

  @bcChatMsgHtml: (from, message, meOrOther, messageHtml = null) ->
    unless messageHtml?
      #messageHtml = $('#tmpl_bc_chat_msg').html()
      messageHtml = TemplateHelper._updateAttributes('tmpl_bc_chat_msg', ['src'])
    toggle = if from.id==currentUser.id then 'left' else 'right'
    messageHtml.
    replace(/\{meOrOther\}/, meOrOther).
    replace(/\{toggle\}/, toggle).
    replace(/\{foto_url\}/, from.foto.url).
    replace(/\{message\}/, message)

  @poisPreviewHTML: (pois) ->
    html = ''
    for poi, i in pois
      poiPreviewHtml = $('#tmpl_poi_preview').html().
      replace(/\{poiId\}/g, poi.id).
      replace(/\{address\}/, poi.address).
      replace(/\{locationId\}/, poi.locationId).
      replace(/\{maxWidth\}/, '300').
      replace(/\{swipeIcon\}/, if i==0 then $('#tmpl_swipe_icon').html() else '')
      swipePanel = ''
      for poiNote, j in poi.notes
        swipePanel += TemplateHelper.swiperSlideHtml(poi, poiNote)
      html += poiPreviewHtml.
      replace(/\{swipePanel\}/, swipePanel)
    html

  @swiperSlideHtml: (poi, poiNote) ->
    maxHeight = VoyageX.View.MAX_SWIPER_SLIDE_HEIGHT
    #maxWidth = 300
    if poiNote.attachment?
      if poiNote.attachment.height?
        scale = maxHeight / poiNote.attachment.height
        width = Math.round(poiNote.attachment.width * scale + 0.49)
      else
        width = 100
    else
      width = 100
   #swiperSlideTmpl = TemplateHelper._updateAttributes('tmpl_swiper_slide', ['src'], TemplateHelper._updateIds('tmpl_swiper_slide')).
    swiperSlideTmpl = TemplateHelper._updateAttributes('tmpl_swiper_slide', ['src'], $('#tmpl_swiper_slide').html()).
    replace(/\{poiId\}/g, poi.id).
    replace(/\{poiNoteId\}/g, poiNote.id).
    #replace(/\{address\}/g, poi.address).
    #replace(/\{attachment_url\}/g, poiNote.attachment.url).
    replace(/\{attachment_url\}/g, TemplateHelper._attachmentPreviewUrl(poiNote.attachment)).
    replace(/\{width\}/g, width).
    replace(/\{height\}/g, maxHeight)

  @locationsBookmarksHTML: (bookmarkLocations) ->
    html = ''
    for location, i in bookmarkLocations
      if location.poi?
        poiOrNoPoiHTML = TemplateHelper._updateAttributes('tmpl_location_bookmark_poi', ['src']).
        replace(/\{attachment_url\}/, location.poi.notes[0].attachment.url)
      else
        poiOrNoPoiHTML = $('#tmpl_location_bookmark_no_poi').html()
      updatedAt = new Date(location.bookmark.updatedAt)
      html = $('#tmpl_location_bookmarks').html().
      replace(/\{location_poi_or_no_poi\}/, poiOrNoPoiHTML).
      replace(/\{locationId\}/g,location.id).
      replace(/\{lat\}/,location.lat).
      replace(/\{lng\}/,location.lng).
      replace(/\{address\}/,location.address).
      replace(/\{bookmark_updated_at\}/, $.datepicker.formatDate('dd.mm.yy', updatedAt)+' '+updatedAt.getHours().toString().replace(/^([0-9])$/,'0$1')+':'+updatedAt.getMinutes().toString().replace(/^([0-9])$/,'0$1')).
      replace(/\{commented_by_user\}/, 'TODO')
    html

  @radarSettingsHtml: () ->
    TemplateHelper._updateIds('tmpl_radar_editor').
    replace(/\{search_radius_meters\}/, VoyageX.SEARCH_RADIUS_METERS)

  @openRadarEditor: () ->
    marker = APP.getOpenPopupMarker()
    unless marker?
      marker = VoyageX.Main.markerManager().get()
    popup = marker.getPopup()
    # note-editor is within existing popup - user, poi or peer - so it should already exist here
    popupHtml = TemplateHelper._resetMarkerControlsPopup popup, 'radar_editor'
#    popupHtml = popup.getContent()
#    if popupHtml.indexOf('note_editor') != -1
#      #popupHtml = popupHtml.replace(/<div[^>]+class="note_editor"(.|\n)+(<div[^>]+id="marker_controls")/, '$1')
#      popupHtml = popupHtml.replace(/<div[^>]+class="note_editor"(.|\n)+/, '$1')
    editorHtml = TemplateHelper.radarSettingsHtml()
    if popupHtml.indexOf('radar_editor') == -1
      popup.setContent popupHtml + editorHtml
      #$('#tmpl_radar_editor > .radar_editor').remove()
    marker.openPopup()
    # init slider:
    $(popup._contentNode).find('> .radar_editor > fieldset').first().trigger('create');
    #noteEditor = $('#'+typeId).closest('.radar_editor').first()
    #noteEditor.closest('.leaflet-popup-content').first().scrollTop(noteEditor.offset().top)
    #$('#'+typeId).focus()
    $('#search_radius_ctrl').slider({
        min: 100,
        max: 5000,
        step: 100,
        value: VoyageX.SEARCH_RADIUS_METERS,
        stop: (event, u) ->
            APP.setSearchRadius u.value
            $('#search_radius_meters').html VoyageX.SEARCH_RADIUS_METERS
    })

  @tracePathEditorHtml: (user, pathKey = null) ->
    tracePathsHtml = ''
    paths = APP.storage().getPaths user
    pathKeys = Object.keys(paths)
    for pathKey in pathKeys
      path = paths[pathKey]
      tracePathsHtml = TemplateHelper._updateIds('tmpl_trace-path_entry').
      replace(/\{date\}/, $.format.date(new Date(path.entries[0].timestamp), 'dd.MM.yyyy HH:mm:ss')).
      replace(/\{user_id\}/, user.id).
      replace(/\{path_key\}/g, path.entries[0].timestamp) + tracePathsHtml
    TemplateHelper._updateIds('tmpl_trace-path_editor').
    replace(/\{trace-paths\}/, tracePathsHtml)

  @openTracePathEditor: (user, pathKey = null) ->
    marker = APP.getOpenPopupMarker()
    unless marker?
      marker = VoyageX.Main.markerManager().get()
    popup = marker.getPopup()
    # note-editor is within existing popup - user, poi or peer - so it should already exist here
    popupHtml = TemplateHelper._resetMarkerControlsPopup popup, 'trace-path_editor'
    editorHtml = TemplateHelper.tracePathEditorHtml user
    if popupHtml.indexOf('trace-path_editor') == -1
      popup.setContent popupHtml + editorHtml
      #$('#tmpl_radar_editor > .radar_editor').remove()
    marker.openPopup()
    # init slider:
    $(popup._contentNode).find('> .radar_editor > fieldset').first().trigger('create');

  @_resetMarkerControlsPopup: (popup, skipKey) ->
    popupHtml = popup.getContent()
    if skipKey == 'note_editor' || popupHtml.indexOf('note_editor') == -1
      #popupHtml = popupHtml.replace(/<div[^>]+class="note_editor"(.|\n)+(<div[^>]+id="marker_controls")/, '$1')
      popupHtml = popupHtml.replace(/<div[^>]+class="note_editor"(.|\n)+/, '$1')
    if skipKey == 'radar_editor' || popupHtml.indexOf('radar_editor') == -1
      #popupHtml = popupHtml.replace(/<div[^>]+class="radar_editor"(.|\n)+(<div[^>]+id="marker_controls")/, '$1')
      popupHtml = popupHtml.replace(/<div[^>]+class="radar_editor"(.|\n)+/, '$1')
    unless skipKey == 'trace-path_editor' || popupHtml.indexOf('trace-path_editor') == -1
      #popupHtml = popupHtml.replace(/<div[^>]+class="trace-path_editor"(.|\n)+(<div[^>]+id="marker_controls")/, '$1')
      popupHtml = popupHtml.replace(/<div[^>]+class="trace-path_editor"(.|\n)+/, '$1')
    popupHtml

  @_addPopupTitle: (contentContainer, marker, location, poi, resetTitle = false) ->
    if resetTitle
      $('#current_address').html(location.address+(if poi? then ' ('+poi.id+')' else ''))
    else
      popupContainer = contentContainer.closest('.leaflet-popup').first()
      #popupContainer.children('.leaflet-popup-close-button').on 'click', VoyageX.Main.closePopupCB(marker)
      popupContainer.prepend('<span id="current_address" style="float: left; padding-left: 5px; font-size: 9px;">'+location.address+(if poi? then ' ('+poi.id+')' else '')+'</span>')

  @_updateIds: (rootElementId, callback = null) ->
    html = $('#'+rootElementId).html()
    $('#'+rootElementId+' [tmpl-id]').each () ->
      #console.log('... replacing '+this.getAttribute('tmpl-id')+' ...')
      unless callback == null
        callback this.getAttribute('tmpl-id')
      curIdRegExpStr = 'tmpl-id=([\'"]?)'+this.getAttribute('tmpl-id')+'[\'"]?'
      regExp = new RegExp(curIdRegExpStr)
      replaceExistingIdRegExp1 = new RegExp('(<[^>]+ '+curIdRegExpStr+'[^>]*) id=["\'][^"\' >]+["\']')
      replaceExistingIdRegExp2 = new RegExp('(<[^>]+) id=["\'][^"\' >]+["\']([^>]* '+curIdRegExpStr+')')
      html = html.
             replace(replaceExistingIdRegExp1, '$1').
             replace(replaceExistingIdRegExp2, '$1$2').
             replace(regExp, 'id=$1'+this.getAttribute('tmpl-id')+'$1')
    html

  @_updateRefs: (rootElementId, html = null, callback = null) ->
    tmplRefPrefix = '_'
    if html == null
      html = $('#'+rootElementId).html()
    $('#'+rootElementId+' [tmpl-ref]').each () ->
      #console.log('... replacing '+this.getAttribute('tmpl-ref')+' ...')
      unless callback == null
        callback this.getAttribute('tmpl-ref')
      # TODO only once per label, clear tmpl-ref attr
      refRegExpStr = new RegExp('(<'+this.localName+'.+?'+this.getAttribute('tmpl-ref')+'=[\'"])'+tmplRefPrefix+'(.+?[\'"])')
      html = html.replace(refRegExpStr, '$1$2')
    html = html.replace(new RegExp(' tmpl-ref=[\'"][^\'"]+[\'"]', 'g'), '')
    html

  @_updateAttributes: (rootElementId, attrs, html = null, callback = null) ->
    if html == null
      html = $('#'+rootElementId).html()
    for attr in attrs
      $('#'+rootElementId+' [tmpl-'+attr+']').each () ->
        #console.log('... replacing '+this.getAttribute('tmpl-'+attr)+' ...')
        unless callback == null
          callback this.getAttribute('tmpl-'+attr)
        # TODO only once per label, clear tmpl-ref attr
        refRegExpStr = new RegExp('(<'+this.localName+'.+?)tmpl-'+attr+'(=[\'"].+?[\'"])')
        html = html.replace(refRegExpStr, '$1'+attr+'$2')
      html = html.replace(new RegExp(' tmpl-'+attr+'=[\'"][^\'"]+[\'"]', 'g'), '')
    html
  
  @_mediaFileTag: (upload, meta) ->
    maxWidth = 100.0
    unless upload?
      return '<img src="'+VoyageX.View.MISSING_ATTACHMENT_IMG_URL+'" style="max-width:'+maxWidth+'px;max-height:'+maxWidth+'px;">'
    scale = -1.0
    height = -1
    switch upload.content_type.match(/^[^:\/]+/)[0]
      when 'image' 
        scale = maxWidth/upload.width
        height = Math.round(upload.height*scale)
        meta.height += height
        '<img src='+upload.url+' style="width:'+maxWidth+'px;height:'+height+'px;">'
      when 'audio'
        '<audio controls>'+
          '<source src="'+upload.url+'" type="'+upload.content_type+'">'+
          'Your browser does not support the audio element.'+
        '</audio>'
      when 'video'
        '<video controls style="max-width:'+maxWidth+'px;">'+
          '<source src="'+upload.url+'" type="'+upload.content_type+'">'+
          'Your browser does not support the video element.'+
        '</video>'
      when 'embed'
        embedType = APP.model().getEmbedType upload.content
        if embedType?
          TemplateHelper._mediaFileTag {url: upload.content, content_type: upload.content_type.replace(/^[^:\/]+./, ''), width: maxWidth, height: maxWidth}, meta
        else
          'unable to display entity with embed_type: '+embedType
      else
        'unable to display entity with content_type: '+upload.content_type

  @_attachmentPreviewUrl: (upload) ->
    unless upload?
      return window.location.origin+'/assets/noise.gif'
    switch upload.content_type.match(/^[^\/]+/)[0]
      when 'image'
        upload.url
      when 'audio'
        '/assets/audio-file.png'
      when 'video'
        '/assets/video-file.png'
      else
        '/assets/no-preview.png'