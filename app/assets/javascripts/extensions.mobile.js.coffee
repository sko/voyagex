jQuery ->

  $(document).on 'click', '.activate_chat', (event) ->
    VoyageX.NavBar.menuNavClick('chat')
    if $('#nav_chat_popup-popup').hasClass('ui-popup-active')
      $('#nav_chat_popup-popup').removeClass('ui-popup-active').addClass('ui-popup-hidden')
  
  $("#nav_chat_popup").on 'popupafterclose', (event, ui) ->
      stopSound()

  # show notification-popup on new chat-messages
  talkExtCB = (message) ->
    console.log 'got a talk - message: ' + message
    if window.document.getElementById('content_chat').style.display == 'none'
      #$('#audio_notify')[0].play()
      window.stopSound = VoyageX.MediaManager.instance().playSound(VoyageX.SOUNDS_MSG_IN_PATH)
      $('#nav_chat_popup_link').click()
  VoyageX.View.instance().addListener 'talk', talkExtCB
