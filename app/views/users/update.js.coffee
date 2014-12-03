$('#user_search_radius_meters').val('')
# TODO handle errors
$('#comm_peer_data').html("<%= j render(partial: '/shared/peers', locals: { user: @user }) -%>")
<% @subscribe.each do |channel_enc_key| %>
for channel in Object.keys(window.commListeners)
  if channel == 'system'
    continue
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+channel_enc_key
  window.subscribeTo.push channelPath
  #window.Comm.StorageController.instance().addToList 'subscribe', 'push', channelPath
  #Comm.Comm._instance().register channelPath, Comm.Comm.channelCallBacksJSON[channel]
<% end %>
<% @un_subscribe.each do |channel_enc_key| %>
for channel in Object.keys(window.commListeners)
  if channel == 'system'
    continue
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+channel_enc_key
  window.unsubscribeFrom.push channelPath
  #window.Comm.StorageController.instance().addToList 'unsubscribe', 'push', channelPath
  #Comm.Comm._instance().deRegistrate channelPath
<% end %>
