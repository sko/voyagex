poisPreview = "<%= j render(partial: 'sandbox/pois_preview') -%>"
locationBookmarks = "<%= j render(partial: 'sandbox/location_bookmarks') -%>"
peopleOfInterest = "<%= j render(partial: 'sandbox/people_of_interest') -%>"
$('#pois_preview').html(poisPreview)
$('#location_bookmarks').html(locationBookmarks)
$('#people_of_interest').html(peopleOfInterest)
<% @pois.each do |poi| %>
#  freeModeFluid: true,
#  mode:'horizontal',
#  loop: false,
#  onSlideChangeEnd: window.photoChanged,
window.myPoiSwiper<%= poi.id -%> = $('#poi_swiper_<%= poi.id -%>').swiper({
  pagination: '.pagination',
  paginationClickable: true,
  centeredSlides: true,
  slidesPerView: 'auto',
  onSlideClick: photoClicked
})
<% end %>
<% if is_mobile %>
$('#open_photo_nav_btn').click()
<% else %>
$('#photo_nav_panel').dialog('open')
if ! $('#photo_nav_panel').parent().hasClass('seethrough_panel')
  $('#photo_nav_panel').parent().addClass('seethrough_panel')
<% end %>
window.mySwiper.reInit()
