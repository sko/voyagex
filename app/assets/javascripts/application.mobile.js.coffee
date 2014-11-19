//= require jquery.mobile
//= require upload_helper

class window.MobileNavBar
#  home_partial_ids = ['content_auth', 'content_uploads']
  @i2FooterNavClick: (clickSrc) ->
    if (clickSrc == 'message')
      $('#content_im').css('display', 'block')
      $('#content_map').css('display', 'none')
      $('#content_home').css('display', 'none')
#      for id in home_partial_ids
#        $('#'+id).css('display', 'none')
    else if (clickSrc == 'map')
      $('#content_im').css('display', 'none')
      $('#content_map').css('display', 'block')
      $('#content_home').css('display', 'none')
#      for id in home_partial_ids
#        $('#'+id).css('display', 'none')
    else if (clickSrc == 'upload')
      $('#content_im').css('display', 'none')
      $('#content_map').css('display', 'none')
      $('#content_home').css('display', 'block')
#      for id in home_partial_ids
#        $('#'+id).css('display', 'block')
    return false

  $('#content_im').css('display', 'none')
  $('#content_map').css('display', 'block')
  $('#content_home').css('display', 'none')
#  for id in home_partial_ids
#    $('#'+id).css('display', 'none')

$(document).on 'click', '.activate_chat', (event) ->
  MobileNavBar.i2FooterNavClick('message')
  if $('#nav_chat_popup-popup').hasClass('ui-popup-active')
    $('#nav_chat_popup-popup').removeClass('ui-popup-active').addClass('ui-popup-hidden')

$(document).on 'click', '.activate_map', (event) ->
  MobileNavBar.i2FooterNavClick('map')

$(document).on 'click', '.activate_upload', (event) ->
  MobileNavBar.i2FooterNavClick('upload')
