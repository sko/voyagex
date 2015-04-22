$('#settings_form').attr('action', '<%= user_path id: tmp_user.id -%>')
#$('.login-link').each () ->
#  $(this).css('display', 'block')
#$('.reg-link').each () ->
#  $(this).css('display', 'block')
$('#sign_up_or_in').first().css('display', 'block')
$('.logout-link').each () ->
  $(this).css('display', 'none')
# you are always someone
<%
geometry = Paperclip::Geometry.from_file(tmp_user.foto)
foto_width = geometry.present? ? geometry.width.to_i : -1
foto_height = geometry.present? ? geometry.height.to_i : -1
%>
window.VoyageX.SEARCH_RADIUS_METERS = <%= tmp_user.search_radius_meters||1000 %>
peers = APP.storage().getPeers()
for peer in peers
  USERS.unsubscribeFromPeerChannels peer
APP.storage().clearCache({tiles: false, poiNotes: false, users: true})
newU = { id: <%= tmp_user.id -%>,\
         username: '<%= tmp_user.username -%>',\
         foto: {url: '<%= tmp_user.foto.url -%>', width: <%= foto_width -%>, height: <%= foto_height -%>},\
         homebaseLocationId: -1,\
         lastLocation: {lat: <%= tmp_user.last_location.latitude -%>, lng: <%= tmp_user.last_location.longitude -%>},\
         curCommitHash: null }
# peerPort is set further down in resetSystemContext
APP.storage().saveCurrentUser newU
APP.view().setupForCurrentUser()
USERS.refreshUserPhoto newU
$('.whoami').each () ->
    $(this).html("<%= t('auth.whoami', username: tmp_user.username) -%>")
$('#whoami_edit').hide()
$('#whoami_nedit').show()
$('#whoami_img_edit').show()
$('#whoami_img_nedit').hide()
$('#comm_peer_data').html("<%= j render(partial: 'shared/peers', locals: {user: tmp_user}) -%>")
# temporary for context-nav - will be changed to template like pois_preview
$('#location_bookmarks').html("<%= j render(partial: 'main/location_bookmarks', locals: {user: tmp_user}) -%>")
$('#people_of_interest').html("<%= j render(partial: 'main/people_of_interest', locals: {user: tmp_user}) -%>")
# unsubscribe from all own channels ...
for channel in VoyageX.Main.commChannels()
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+Comm.Comm.channelCallBacksJSON[channel].channel_enc_key
  Comm.Comm.unsubscribeFrom channelPath, true
Comm.Comm.resetSystemContext <%= tmp_user.id %>
