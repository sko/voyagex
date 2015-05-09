class window.VoyageX.ChatControl

  @_SINGLETON = null

  constructor: () ->
    ChatControl._SINGLETON = this
    window.CHAT = this
    $('#message').on 'keyup', (event) ->
      if (event.which == 13 || event.keyCode == 13)
        event.preventDefault()
        publishText = $(this).val().replace(/\s*$/,'')
        unless publishText.trim() == ''
          APP.bcChatMessage(publishText)
          VoyageX.View.addChatMessage { text: $('#message').val() }
  
  # called when chat-window is initialized
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

  initBCChatMessages: () ->
    conference = APP.storage().getChat()
    entries = []
    if conference?
      entryKeys = Object.keys(conference).sort()
      for entryKey, i in entryKeys
        entries.push conference[entryKey]
        userId = parseInt Object.keys(conference[entryKey])[0]
        user = APP.storage().getUser userId
        message = {peer: user, text: conference[entryKey][userId]}
        VoyageX.View.addChatMessage message, user.id == APP.user().id
    entries

  initP2PChatMessages: (peer, messages) ->
    chat = APP.storage().getChat peer
    if chat?
      # msgKeys = Object.keys(chat).sort()
      # for msgKey, i in msgKeys
      #   messages.push chat[msgKey]
      entryKeys = Object.keys(chat).sort()
      for entryKey, i in entryKeys
        userId = parseInt Object.keys(chat[entryKey])[0]
        from = if userId == peer.id then peer else APP.user()
        messages.push {from: from, text: chat[entryKey][userId]}
    messages
