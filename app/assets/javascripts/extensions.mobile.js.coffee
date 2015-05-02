jQuery ->

  $(document).on 'click', '.activate_chat', (event) ->
    VoyageX.NavBar.menuNavClick('chat')
    # if $('#system_message_popup-popup').hasClass('ui-popup-active')
    #   $('#system_message_popup-popup').removeClass('ui-popup-active').addClass('ui-popup-hidden')
    stopSound()
    APP.closeSystemMessage('popup')
  
  # $("#system_message_popup").on 'popupafterclose', (event, ui) ->
  #     stopSound()

  # show notification-popup on new chat-messages
  talkExtCB = (message) ->
    console.log 'got a talk - message: ' + message
    if window.document.getElementById('content_chat').style.display == 'none'
      window.stopSound = VoyageX.MediaManager.instance().playSound(VoyageX.SOUNDS_MSG_IN_PATH)
      #$('#system_message_popup_link').click()
      APP.showSystemMessage (systemMessageDiv) ->
          systemMessageDiv.html $('#tmpl_message_received_popup').html()
        , null, 'popup'
  VoyageX.View.instance().addListener 'talk', talkExtCB
