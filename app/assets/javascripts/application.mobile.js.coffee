//= require jquery.mobile

class window.MobileNavBar
  toggleFootNavCurSrc = 'map'

  @i2FooterNavClick: (clickSrc) ->
    if (clickSrc == 'message')
      window.document.getElementById('content_im').style.display = 'block'
      window.document.getElementById('content_map').style.display = 'none'
    else if (clickSrc == 'map')
      window.document.getElementById('content_im').style.display = 'none'
      window.document.getElementById('content_map').style.display = 'block'
    toggleFootNavCurSrc = clickSrc
    return false

  window.document.getElementById('content_im').style.display = 'none'
  window.document.getElementById('content_map').style.display = 'block'

$(document).on 'click', '.activate_chat', (event) ->
  MobileNavBar.i2FooterNavClick('message')
  if $('#nav_chat_popup-popup').hasClass('ui-popup-active')
    $('#nav_chat_popup-popup').removeClass('ui-popup-active').addClass('ui-popup-hidden')

$(document).on 'click', '.activate_map', (event) ->
  MobileNavBar.i2FooterNavClick('map')