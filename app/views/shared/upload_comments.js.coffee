APP.panPosition(<%= @upload.attached_to.poi.location.latitude -%>,<%= @upload.attached_to.poi.location.longitude -%>,'<%= escape_javascript(@upload.attached_to.poi.location.address).html_safe -%>')
VoyageX.Main.markerManager().get().bindPopup("<%= j render(partial: 'shared/upload_comments') -%>").openPopup({minWidth: '100px'});
$('.leaflet-popup-close-button').on 'click', (event) ->
  VoyageX.Main.markerManager().get().unbindPopup()
  $('.leaflet-popup').remove()
$('#upload_comment_btn_<%= @upload.id -%>').on 'click', (event) ->
  #openUploadCommentControls(<%= @upload.id -%>);
  $('#upload_comment_conrols').dialog('open')
  if ! $('#upload_comment_conrols').parent().hasClass('seethrough_panel')
    $('#upload_comment_conrols').parent().addClass('seethrough_panel')
<% if is_mobile %>
$('#upload_comment_container').html("<%= j render(partial: 'uploads/form/comment_data.mobile', locals: {resource: @upload, resource_name: :upload}) -%>")
<% else %>
$('#upload_comment_container').html("<%= j render(partial: 'uploads/form/comment_data', locals: {resource: @upload, resource_name: :upload}) -%>")
<% end %>
