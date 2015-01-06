class window.VoyageX.TemplateHelper
 
  @_SINGLETON = null

  @poiNoteInputHtml: (parentElementId, poiNote = null) ->
    html = $('#tmpl_poi_note_input').html()
    formId = null
    html = TemplateHelper._updateIds 'tmpl_poi_note_input', (cur) ->
        if cur.match(/_form$/) != null
          formId = cur
    html = TemplateHelper._updateRefs 'tmpl_poi_note_input', html
    $('#'+parentElementId).html(html)
    if poiNote != null && formId != null
      methodDiv = $('#'+formId+' > div').first()
      methodDiv.append('<input type="hidden" name="_method" value="put">')
      $('#'+formId).attr('action', updateActionPathTmpl.replace(/:id/, poiNote.id))

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
    #toggle = if i%2==0 then 'left' else 'right'
    toggle = if poiNote.user.id==currentUser.id then 'left' else 'right'
    poiNoteTmpl.
    replace(/\{poi_note_id\}/g, poiNote.id).
    replace(/\{i\}/g, i).
    replace(/\{toggle\}/g, toggle).
    replace(/\stmpl-toggle=['"]?[^'" >]+/g, '').
    replace(/\{media_file_tag\}/, TemplateHelper._mediaFileTag(poiNote.attachment, meta)).
    replace(/\{username\}/, poiNote.user.username).
    replace(/\{comment\}/, padTextHtml(poiNote.text, 80))

  @poiNotePopupHtml: (poi, meta) ->
    popupHtml = TemplateHelper._updateIds 'tmpl_poi_notes_container'
    poiNoteTmpl = TemplateHelper._updateIds 'tmpl_poi_note'
    poiNotesHtml = ''
    for poiNote, i in poi.notes
      poiNotesHtml += TemplateHelper.poiNotePopupEntryHtml(poiNote, poiNoteTmpl, i, meta)
    popupHtml = popupHtml.
                #replace(/\{address\}/g, poi.address).
                replace(/\{poi_notes\}/, poiNotesHtml).
                replace(/\{poi_id\}/g, poi.id)

  @openPOINotePopup: (poi, marker = null) ->
    meta = {height: 0}
    popupHtml = TemplateHelper.poiNotePopupHtml(poi, meta)
    if marker == null
      marker = APP.getMarker poi
    popup = marker.getPopup()
    isNewPopup = !popup?
    if isNewPopup
      popup = L.popup {minWidth: 200, maxHeight: 300}
      marker.bindPopup(popup)
      marker.off('click', marker.togglePopup, marker)
      # popupclose doesn't work if just popup is closed because of other marker's opening popup
      marker.on 'popupclose', (event) -> 
          console.log('openPOINotePopup: popupclose for '+VoyageX.Main.markerManager().toString(event.target))
    popup.setContent(popupHtml)
    marker.openPopup()
    VoyageX.Main.markerManager().userMarkerMouseOver false
    if isNewPopup
      poiNoteContainer = $('#poi_notes_container')
      TemplateHelper._addPopupTitle poiNoteContainer, marker, Comm.StorageController.instance().getLocation(poi.locationId), poi
    $('#poi_note_input').html('')
    TemplateHelper.poiNoteInputHtml('poi_note_input', poi.notes[0])

  @addPoiNotes: (poi, newNotes, marker) ->
    popup = marker.getPopup()
    if popup?
     #i = $('.leaflet-popup .upload_comment').length
      i = poi.notes.length - newNotes.length
      newPopupHtml = ''
      for note, j in newNotes
        newPopupHtml += TemplateHelper.poiNotePopupHtmlFromTmpl(note, i+j)
      popupHtml = popup.getContent().replace(/(<span[^>]*>\s*<div[^>].+?upload_comment_btn_)/, newPopupHtml+'$1')
      popup.setContent(popupHtml)
      #$('#poi_notes_container div.upload_comment').last().prepend(newPopupHtml)
      #popup.update()
      unless popup._isOpen
        marker.openPopup()
        VoyageX.Main.markerManager().userMarkerMouseOver false
    else
      TemplateHelper.openPOINotePopup poi, marker

  @openMarkerControlsPopup: () ->
    marker = VoyageX.Main.markerManager().get()
    popupHtml = TemplateHelper._updateIds 'tmpl_marker_controls'
   #popup = TemplateHelper._verifyPopup marker, 'marker_controls'
    popup = marker.getPopup()
    isNewPopup = !popup?
    if isNewPopup
      marker.bindPopup popupHtml
      marker.off('click', marker.togglePopup, marker)
      # popupclose doesn't work if just popup is closed because of other marker's opening popup
      marker.on 'popupclose', (event) ->
          console.log('openMarkerControlsPopup: popupclose for '+VoyageX.Main.markerManager().toString(event.target))
    else
      popup.setContent popupHtml
    marker.openPopup()
    if isNewPopup
      poiNoteContainer = $('#marker_controls')
      TemplateHelper._addPopupTitle poiNoteContainer, marker, {address: ''}#Comm.StorageController.instance().getLocation(poi.locationId)

  @openNoteEditor: (bookmark) ->
    marker = APP.getOpenPopupMarker()
    unless marker?
      marker = VoyageX.Main.markerManager().get()

    editorHtml = TemplateHelper._updateIds('tmpl_note_editor').
    replace(/\{locationId\}/g, bookmark.location.id).
    replace(/\{text\}/, if bookmark.text? then bookmark.text else '')
    popup = marker.getPopup()
# note-editor is within existing popup - user or poi - so it should already exist here
#    isNewPopup = !popup?
#    if isNewPopup
#      popupHtml = TemplateHelper._updateIds 'tmpl_marker_controls'
#      marker.bindPopup popupHtml + editorHtml
#      marker.off('click', marker.togglePopup, marker)
#      # popupclose doesn't work if just popup is closed because of other marker's opening popup
#      marker.on 'popupclose', (event) ->
#          console.log('openNoteEditor: popupclose for current marker ... TODO')
#    else
    popupHtml = popup.getContent()
    if popupHtml.indexOf('note_editor') == -1
      popup.setContent popupHtml + editorHtml
    marker.openPopup()
#    if isNewPopup
#      $('#marker_controls').closest('.leaflet-popup').children('.leaflet-popup-close-button').on 'click', VoyageX.Main.closePopupCB(marker)
    $('#note').focus()
    noteEditor = $('#note_editor')
    noteEditor.closest('.leaflet-popup-content').first().scrollTop(noteEditor.offset().top)

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
    maxHeight = 100.0
    maxWidth = 300
    scale = maxHeight / poiNote.attachment.height
    width = Math.round(poiNote.attachment.width * scale + 0.49)
   #swiperSlideTmpl = TemplateHelper._updateAttributes('tmpl_swiper_slide', ['src'], TemplateHelper._updateIds('tmpl_swiper_slide')).
    swiperSlideTmpl = TemplateHelper._updateAttributes('tmpl_swiper_slide', ['src'], $('#tmpl_swiper_slide').html()).
    replace(/\{poiId\}/g, poi.id).
    replace(/\{poiNoteId\}/g, poiNote.id).
    #replace(/\{address\}/g, poi.address).
    replace(/\{attachment_url\}/g, poiNote.attachment.url).
    replace(/\{width\}/g, width).
    replace(/\{height\}/g, maxHeight)

  @locationsBookmarksHTML: (bookmarks) ->
    html = ''
    for bookmark, i in bookmarks
      if bookmark.location.poi?
        poiOrNoPoiHTML = TemplateHelper._updateAttributes('tmpl_location_bookmark_poi', ['src']).
        replace(/\{attachment_url\}/, bookmark.location.poi.notes[0].attachment.url)
      else
        poiOrNoPoiHTML = $('#tmpl_location_bookmark_no_poi').html()
      html = $('#tmpl_location_bookmarks').html().
      replace(/\{location_poi_or_no_poi\}/, poiOrNoPoiHTML).
      replace(/\{locationId\}/g, bookmark.location.id).
      replace(/\{lat\}/, bookmark.location.lat).
      replace(/\{lng\}/, bookmark.location.lng).
      replace(/\{address\}/, bookmark.location.address).
      replace(/\{bookmark_updated_at\}/, bookmark.updatedAt).
      replace(/\{commented_by_user\}/, 'TODO')
    html

  @_addPopupTitle: (contentContainer, marker, location, poi) ->
    popupContainer = contentContainer.closest('.leaflet-popup').first()
    popupContainer.children('.leaflet-popup-close-button').on 'click', VoyageX.Main.closePopupCB(marker)
    popupContainer.prepend('<span id="current_address" style="float: left;">'+location.address+(if poi? then ' ('+poi.id+')' else '')+'</span>')

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
    scale = -1.0
    height = -1
    switch upload.content_type.match(/^[^\/]+/)[0]
      when 'image' 
        maxWidth = 100.0
        scale = maxWidth/upload.width
        height = Math.round(upload.height*scale)
        meta.height += height
        '<img src='+upload.url+' style="width:'+maxWidth+'px;height:'+height+'px;">'
      when 'audio'
        '<audio controls: "controls">'+
          '<source src="'+upload.url+'" type="'+upload.content_type+'">'+
          'Your browser does not support the audio element.'+
        '</audio>'
      when 'video'
        '<video controls: "controls">'+
          '<source src="'+upload.url+'" type="'+upload.content_type+'">'+
          'Your browser does not support the video element.'+
        '</video>'
      else
        'unable to display entity with content_type: '+upload.content_type
