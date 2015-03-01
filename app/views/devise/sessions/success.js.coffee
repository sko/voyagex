$('#settings_form').attr('action', '<%= user_path id: current_user.id -%>')
#$('.login-link').each () ->
#  $(this).css('display', 'none')
#$('.reg-link').each () ->
#  $(this).css('display', 'none')
$('#sign_up_or_in').first().css('display', 'none')
$('.logout-link').each () ->
  $(this).css('display', 'block')
<% if is_mobile -%>
$('#sign_in_cancel').click()
<% end -%>
<%
if current_user.snapshot.location.present?
  lat = current_user.snapshot.location.latitude
  lng = current_user.snapshot.location.longitude
else
  lat = current_user.snapshot.lat
  lng = current_user.snapshot.lng
end
%>
window.VoyageX.SEARCH_RADIUS_METERS = <%= current_user.search_radius_meters||100 %>
window.currentUser = { id: <%= current_user.id -%>,\
                       username: '<%= current_user.username -%>',\
                       homebaseLocationId: <%= current_user.home_base.present? ? current_user.home_base.id : -1 -%>,\
                       lastLocation: {lat: <%= lat -%>, lng: <%= lng -%>},\
                       curCommitHash: '<%= current_user.snapshot.cur_commit.hash_id -%>' }
$('.whoami').each () ->
  $(this).html("<%= escape_javascript(link_to t('auth.whoami', username: current_user.username), change_username_path, class: 'navbar-inverse navbar-brand', data: { remote: 'true', format: :js }) -%>")
$('#comm_peer_data').html("<%= j render(partial: 'shared/peers', locals: {user: current_user}) -%>")
# temporary for photonav - will be changed to template like pois_preview
$('#location_bookmarks').html("<%= j render(partial: 'sandbox/location_bookmarks', locals: {user: current_user}) -%>")
$('#people_of_interest').html("<%= j render(partial: 'sandbox/people_of_interest', locals: {user: current_user}) -%>")
# first unsubscripe old channels before subscribing new - TODO: check if faye handles thso orderly
for channel in VoyageX.Main.commChannels()
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+Comm.Comm.channelCallBacksJSON[channel].channel_enc_key
  Comm.Comm.unsubscribeFrom channelPath, true
Comm.Comm.resetSystemContext <%= current_user.id %>
APP.initPeers()