# GOOD but now from template ... poisPreview = "<%= j render(partial: 'sandbox/pois_preview') -%>"
locationBookmarks = "<%= j render(partial: 'sandbox/location_bookmarks') -%>"
peopleOfInterest = "<%= j render(partial: 'sandbox/people_of_interest') -%>"
# GOOD but now from template ... $('#pois_preview').html(poisPreview)
$('#location_bookmarks').html(locationBookmarks)
$('#people_of_interest').html(peopleOfInterest)
# GOOD but now from template ... 
#<% @pois.each do |poi| %>
##  freeModeFluid: true,
##  mode:'horizontal',
##  loop: false,
##  onSlideChangeEnd: window.photoChanged,
##  pagination: '.pagination_<%= poi.id -%>',
##  paginationClickable: true,
#window.myPoiSwiper<%= poi.id -%> = $('#poi_swiper_<%= poi.id -%>').swiper({
#  createPagination: false,
#  centeredSlides: true,
#  slidesPerView: 'auto',
#  onSlideClick: photoClicked
#})
## if first image is swipe-icon
##window.myPoiSwiper<%= poi.id -%>.swipeNext()
#<% end %>
<% if is_mobile %>
$('#open_photo_nav_btn').click()
<% else %>
$('#photo_nav_panel').dialog('open')
if ! $('#photo_nav_panel').parent().hasClass('seethrough_panel')
  $('#photo_nav_panel').parent().addClass('seethrough_panel')
<% end %>
# select initial tab
$('#pois_preview_btn').click()
