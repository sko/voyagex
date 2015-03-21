class window.VoyageX.ChatControl

  @_SINGLETON = null

  constructor: () ->
    ChatControl._SINGLETON = this
    $('#message').on 'keyup', (event) ->
      if (event.which == 13 || event.keyCode == 13)
        event.preventDefault()
        publishText = $(this).val()
        APP.bcChatMessage(publishText)
        VoyageX.View.addChatMessage { text: $('#message').val() }
    #$('.p2p_message').on 'keyup', (event) ->
    window.sendP2PChatMessage = (event) ->
      if (event.which == 13 || event.keyCode == 13)
        event.preventDefault()
        publishText = $(event.target).val().replace(/\s*$/,'')
        unless publishText.trim() == ''
          peerChatContainer = $(event.target).closest('div[id^=peer_popup_]').first()
          peerId = parseInt peerChatContainer.attr('id').match(/[0-9]+$/)[0]
          peer = Comm.StorageController.instance().getUser peerId
          APP.p2pChatMessage(peer, publishText)
          VoyageX.View.addChatMessage { text: $('#p2p_message_'+peerId).val() }, true, {peer: peer, chatContainer: peerChatContainer, msgInput: $(event.target)}
  
  addP2PMsgInput: (msgInputSelector) ->
    msgInputSelector.on 'keyup', (event) ->
      if (event.which == 13 || event.keyCode == 13)
        event.preventDefault()
        APP.chat().sendP2PChatMessage $(event.target)#==msgInputSelector
  
  sendP2PChatMessage: (msgInputSelector) ->
    publishText = msgInputSelector.val().replace(/\s*$/,'')
    unless publishText.trim() == ''
      peerChatContainer = msgInputSelector.closest('div[id^=peer_popup_]').first()
      peerId = parseInt peerChatContainer.attr('id').match(/[0-9]+$/)[0]
      peer = Comm.StorageController.instance().getUser peerId
      APP.p2pChatMessage(peer, publishText)
      VoyageX.View.addChatMessage { text: $('#p2p_message_'+peerId).val() }, true, {peer: peer, chatContainer: peerChatContainer, msgInput: msgInputSelector}
