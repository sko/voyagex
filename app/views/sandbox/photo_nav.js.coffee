$('#upload_preview').html("<%= j render(partial: 'sandbox/swipe_panel') -%>");
<% if is_mobile %>
$('#open_photo_nav_btn').click()
<% else %>
$('#photo_nav_panel').dialog('open')
if ! $('#photo_nav_panel').parent().hasClass('seethrough_panel')
  $('#photo_nav_panel').parent().addClass('seethrough_panel')
<% end %>
window.mySwiper.reInit()
