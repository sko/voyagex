jQuery ->

  talkExtCB = (message) ->
    console.log 'got a talk - message: ' + message
    if window.document.getElementById('content_im').style.display == 'none'
      $('#nav_chat_popup_link').click()

  window.commListeners.talk.push(talkExtCB);
