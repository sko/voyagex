# required partial-param (locals): channel_enc_key
for channel in VoyageX.Main.commChannels()
  if channel == 'system'
    continue
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+'<%=channel_enc_key%>'
  window.subscribeTo.push channelPath
  #window.Comm.StorageController.instance().addToList 'subscribe', 'push', channelPath
  #Comm.Comm.subscribeTo channelPath, Comm.Comm.channelCallBacksJSON[channel]
#APP.storage().saveUser {id: #{cs.user.id}, username: '#{cs.user.username}', peerPort: {id: #{cs.id}, channel_enc_key: '#{cs.channel_enc_key'}});
