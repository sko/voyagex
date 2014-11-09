class window.Comm
  client = null
  channelCallBacksJSON = null

  constructor: (channelCallBacksList) ->
    client = new Faye.Client(document.location.origin+'/comm')
    channelCallBacksJSON = new Object()
    for pair in channelCallBacksList
      channelCallBacksJSON[pair[0].substr(1)] = pair[1]
      Comm.register(pair[0], pair[1])

  send: (channel, message) ->
    client.publish(channel, message)

  @register: (channel, callBack) ->
    client.subscribe channel, (message) ->
      callBack(message)
