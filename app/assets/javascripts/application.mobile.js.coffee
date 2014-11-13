//= require jquery.mobile

class window.MobileNavBar

  @i2FooterNavClick: (clickSrc) ->
    if (clickSrc == 'message')
      $('#content_im').css('display', 'block')
      $('#content_map').css('display', 'none')
    else if (clickSrc == 'map')
      $('#content_im').css('display', 'none')
      $('#content_map').css('display', 'block')
    return false

  $('#content_im').css('display', 'none')
  $('#content_map').css('display', 'block')

$(document).on 'click', '.activate_chat', (event) ->
  MobileNavBar.i2FooterNavClick('message')
  if $('#nav_chat_popup-popup').hasClass('ui-popup-active')
    $('#nav_chat_popup-popup').removeClass('ui-popup-active').addClass('ui-popup-hidden')

$(document).on 'click', '.activate_map', (event) ->
  MobileNavBar.i2FooterNavClick('map')