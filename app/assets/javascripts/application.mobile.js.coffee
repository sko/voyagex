offlineZooms = [4,8,12,16]
zooms = [1..16]
mapOptions = {
               zooms: zooms
               zoom: 16
               subdomains: ['a']
               access_token: 'pk.eyJ1Ijoic3RlcGhhbmtvZWxsZXIiLCJhIjoiZEFHdnhwayJ9.AdtZiG5HGi5JAb64G1K-jA'
               max_zoom: 30
             }
new VoyageX.Main(mapOptions, offlineZooms, true) 

$(document).on 'click', '.activate_map', (event) ->
  VIEW_MODEL.menuNavClick('map')

$(document).on 'click', '.activate_upload', (event) ->
  VIEW_MODEL.menuNavClick('home')

window.hideAjaxLoading = () ->
  $('html').first().removeClass('ui-loading')
  $('html').first().removeClass('ui-overlay-a')

#window.hideAddressBar = () ->
#  if(!window.location.hash)
#    if(document.height < window.outerHeight)
#        document.body.style.height = (window.outerHeight + 50) + 'px'
#    setTimeout(() ->
#        window.scrollTo(0, 1)
#    , 50)
# Main.onload 
#window.addEventListener("load", () ->
#    if(!window.pageYOffset)
#      hideAddressBar()
#  )
#window.addEventListener("orientationchange", hideAddressBar)