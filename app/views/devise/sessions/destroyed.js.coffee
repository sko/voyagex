$('.login-link').each () ->
  $(this).css('display', 'block')
$('.reg-link').each () ->
  $(this).css('display', 'block')
$('.logout-link').each () ->
  $(this).css('display', 'none')
# you are always someone
VoyageX.SEARCH_RADIUS_METERS = <%= tmp_user.search_radius_meters||100 %>
currentUser = { id: <%= tmp_user.id -%>, username: '<%= tmp_user.username -%>' }
$('.whoami').each () ->
  $(this).html("<%= escape_javascript(link_to t('auth.whoami', username: tmp_user.username), change_username_path, class: 'navbar-inverse navbar-brand', data: { remote: 'true', format: :js }) -%>")
for channel in VoyageX.Main.commChannels()
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+Comm.Comm.channelCallBacksJSON[channel].channel_enc_key
  Comm.Comm.unsubscribeFrom channelPath, true
Comm.Comm.resetSystemContext <%= tmp_user.id %>
$('#comm_peer_data').html("<%= j render(partial: 'shared/peers', locals: {user: tmp_user}) -%>")
# temporary for photonav - will be changed to template like pois_preview
$('#location_bookmarks').html("<%= j render(partial: 'sandbox/location_bookmarks', locals: {user: tmp_user}) -%>")
$('#people_of_interest').html("<%= j render(partial: 'sandbox/people_of_interest', locals: {user: tmp_user}) -%>")
