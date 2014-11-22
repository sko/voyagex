panPosition(<%= @upload.location.latitude -%>,<%= @upload.location.longitude -%>,'<%= escape_javascript(@upload.location.address).html_safe -%>')
markerManager.get().bindPopup("<%= j render(partial: 'shared/upload_comments') -%>").openPopup({minWidth: '100px'});
$('#upload_comment_btn_<%= @upload.id -%>').on 'click', (event) ->
  openUploadCommentControls(<%= @upload.id -%>);
$('#add_upload_comment_upload_id').val(<%= @upload.id -%>)
