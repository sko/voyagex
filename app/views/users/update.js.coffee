#$('#user_search_radius_meters').val('')
VoyageX.SEARCH_RADIUS_METERS = <%= @user.search_radius_meters||100 %>
# TODO handle errors
$('#comm_peer_data').html("<%= j render(partial: '/shared/peers', locals: { user: @user }) -%>")
<% if is_mobile %>
$('#comm_peer_data').trigger("create")
<% end %>
<% @un_subscribe.each do |channel_enc_key| %>
for channel in VoyageX.Main.commChannels()
  if channel == 'system'
    continue
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+'<%=channel_enc_key%>'
  #window.unsubscribeFrom.push channelPath
  #window.Comm.StorageController.instance().addToList 'unsubscribe', 'push', channelPath
  Comm.Comm.unsubscribeFrom channelPath
<% end %>
