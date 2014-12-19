class window.VoyageX.TemplateHelper
 
  @_SINGLETON = null

  @poiNoteInputHtml: (parentElementId, poiNote = null) ->
    html = $('#tmpl_poi_note_input').html()
    formId = null
    $('#tmpl_poi_note_input [tmpl-id]').each () ->
      console.log('... replacing '+this.getAttribute('tmpl-id')+' ...')
      if this.getAttribute('tmpl-id').match(/_form$/) != null
        formId = this.getAttribute('tmpl-id')
      curIdRegExpStr = 'tmpl-id=([\'"]?)'+this.getAttribute('tmpl-id')+'[\'"]?'
      regExp = new RegExp(curIdRegExpStr)
      replaceExistingIdRegExp1 = new RegExp('(<[^>]+ '+curIdRegExpStr+'[^>]*) id=["\']?[^"\' >]+["\']?')
      replaceExistingIdRegExp2 = new RegExp('(<[^>]+) id=["\']?[^"\' >]+["\']?([^>]* '+curIdRegExpStr+')')
      html = html.
             replace(replaceExistingIdRegExp1, '$1').
             replace(replaceExistingIdRegExp2, '$1$2').
             replace(regExp, 'id=$1'+this.getAttribute('tmpl-id')+'$1')
    $('#'+parentElementId).html(html)
    if poiNote != null && formId != null
      methodDiv = $('#'+formId+' > div').first()
      methodDiv.append('<input type="hidden" name="_method" value="put">')
      $('#'+formId).attr('action', updateActionPathTmpl.replace(/:id/, poiNote.id))

  @updateIds: (rootElementId, callback = null) ->
    html = $('#'+rootElementId).html()
    $('#'+rootElementId+' [tmpl-id]').each () ->
      console.log('... replacing '+this.getAttribute('tmpl-id')+' ...')
      unless callback == null
        callback this.getAttribute('tmpl-id')
      curIdRegExpStr = 'tmpl-id=([\'"]?)'+this.getAttribute('tmpl-id')+'[\'"]?'
      regExp = new RegExp(curIdRegExpStr)
      replaceExistingIdRegExp1 = new RegExp('(<[^>]+ '+curIdRegExpStr+'[^>]*) id=["\']?[^"\' >]+["\']?')
      replaceExistingIdRegExp2 = new RegExp('(<[^>]+) id=["\']?[^"\' >]+["\']?([^>]* '+curIdRegExpStr+')')
      html = html.
             replace(replaceExistingIdRegExp1, '$1').
             replace(replaceExistingIdRegExp2, '$1$2').
             replace(regExp, 'id=$1'+this.getAttribute('tmpl-id')+'$1')
    html

  @poiNotePopupHtmlFromTmpl: (poiNote, i, addContainer = false) ->
    html = TemplateHelper.updateIds 'tmpl_poi_note'
    poiNotesHtml = TemplateHelper.poiNotePopupEntryHtml(poiNote, html, i)
    if addContainer
      popupHtml = TemplateHelper.updateIds 'tmpl_poi_notes_container'
      popupHtml = popupHtml.
                  replace(/\{poi_notes\}/, poiNotesHtml).
                  replace(/\{base_poi_note_id\}/, poiNote.id)
    else
      poiNotesHtml

  @poiNotePopupEntryHtml: (poiNote, poiNoteTmpl, i) ->
    poiNoteTmpl.
    replace(/\{i\}/g, i).
    replace(/\{media_file_tag\}/, TemplateHelper._mediaFileTag(poiNote.attachment)).
    replace(/\{username\}/, poiNote.user.username).
    replace(/\{comment\}/, poiNote.text)

  @poiNotePopupHtml: (poi) ->
    popupHtml = TemplateHelper.updateIds 'tmpl_poi_notes_container'
    poiNoteTmpl = TemplateHelper.updateIds 'tmpl_poi_note'
    poiNotesHtml = ''
    for poiNote, i in poi.notes
      poiNotesHtml += TemplateHelper.poiNotePopupEntryHtml(poiNote, poiNoteTmpl, i)
#      poiNotesHtml += poiNoteTmpl.
#                      replace(/\{i\}/g, i).
#                      replace(/\{media_file_tag\}/, TemplateHelper._mediaFileTag(poiNote.attachment)).
#                      replace(/\{username\}/, poiNote.user.username).
#                      replace(/\{comment\}/, poiNote.text)
    popupHtml = popupHtml.
                replace(/\{poi_notes\}/, poiNotesHtml).
                replace(/\{base_poi_note_id\}/, poi.notes[0].id)

  @openPOINotePopup: (poi) ->
    panPosition(poi.lat, poi.lng, poi.address)
    popupHtml = TemplateHelper.poiNotePopupHtml(poi)
    VoyageX.Main.markerManager().get().bindPopup(popupHtml).openPopup({minWidth: '100px'})
    $('#poi_notes_container').scrollpanel({
        prefix: 'pcn-'
      })
    $('.leaflet-popup-close-button').on 'click', (event) ->
      VoyageX.Main.markerManager().get().unbindPopup()
      $('.leaflet-popup').remove()
    $('#upload_comment_btn_'+poi.notes[0].id).on 'click', (event) ->
      openUploadCommentControls(poi.notes[0].id)
      #$('#upload_comment_conrols').dialog('open')
      #if ! $('#upload_comment_conrols').parent().hasClass('seethrough_panel')
      #  $('#upload_comment_conrols').parent().addClass('seethrough_panel')
    TemplateHelper.poiNoteInputHtml('poi_note_input', poi.notes[0])
  
  @_mediaFileTag: (upload) ->
    switch upload.content_type.match(/^[^\/]+/)[0]
      when 'image' 
        maxWidth = 100
        '<img src='+upload.url+' style="width:'+maxWidth+'px;">'
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
