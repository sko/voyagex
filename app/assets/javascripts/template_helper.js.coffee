class window.VoyageX.TemplateHelper
 
  @_SINGLETON = null

  @poiNoteInputHtml: () ->
    html = $('#tmpl_poi_note_input').html()
    $('#tmpl_poi_note_input [tmpl-id]').each () ->
      console.log('... replacing '+this.getAttribute('tmpl-id')+' ...')
      curIdRegExpStr = 'tmpl-id=([\'"]?)'+this.getAttribute('tmpl-id')+'[\'"]?'
      regExp = new RegExp(curIdRegExpStr)
      replaceExistingIdRegExp1 = new RegExp('(<[^>]+ '+curIdRegExpStr+'[^>]*) id=["\']?[^"\' >]+["\']?')
      replaceExistingIdRegExp2 = new RegExp('(<[^>]+) id=["\']?[^"\' >]+["\']?([^>]* '+curIdRegExpStr+')')
      html = html.replace(replaceExistingIdRegExp1, '$1').
             replace(replaceExistingIdRegExp2, '$1$2').
             replace(regExp, 'id=$1'+this.getAttribute('tmpl-id')+'$1')
    html
  
  @openPOINoteInput: (poi) ->
    panPosition(poi.lat, poi.lng, poi.address)
    popupHtml = $('#tmpl_poi_notes_container').html()
    poiNoteTmpl = $('#tmpl_poi_note').html()
    poiNotesHtml = ''
    for poiNote, i in poi.notes
      poiNotesHtml += poiNoteTmpl.
                      replace(/\{i\}/g, i).
                      replace(/\{media_file_tag\}/, TemplateHelper._mediaFileTag(poiNote.attachment)).
                      replace(/\{username\}/, poiNote.user.username).
                      replace(/\{comment\}/, poiNote.text)
    popupHtml = popupHtml.
                replace(/\{poi_notes\}/, poiNotesHtml).
                replace(/\{base_poi_note_id\}/, poi.notes[0].id)
    VoyageX.Main.markerManager().get().bindPopup(popupHtml).openPopup({minWidth: '100px'})
    $('.leaflet-popup-close-button').on 'click', (event) ->
      VoyageX.Main.markerManager().get().unbindPopup()
      $('.leaflet-popup').remove()
    $('#upload_comment_btn_'+poi.notes[0].id).on 'click', (event) ->
      #openUploadCommentControls(poi.notes[0].attachment.id)
      $('#upload_comment_conrols').dialog('open')
      if ! $('#upload_comment_conrols').parent().hasClass('seethrough_panel')
        $('#upload_comment_conrols').parent().addClass('seethrough_panel')
    #if isMobile()
    #  $('#upload_comment_container').html("<%= j render(partial: 'uploads/form/comment_data.mobile', locals: {resource: @upload, resource_name: :upload}) -%>")
    #else
    #  $('#upload_comment_container').html("<%= j render(partial: 'uploads/form/comment_data', locals: {resource: @upload, resource_name: :upload}) -%>")
    poiNoteInputHtml = TemplateHelper.poiNoteInputHtml()
    $('#upload_comment_container').html(poiNoteInputHtml)
  
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
