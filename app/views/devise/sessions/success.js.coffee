$('.login-link').each () ->
  $(this).css('display', 'none')
$('.reg-link').each () ->
  $(this).css('display', 'none')
$('.logout-link').each () ->
  $(this).css('display', 'block')
<% if is_mobile -%>
$('#sign_in_cancel').click()
<% end -%>
$('.whoami').each () ->
  $(this).html("<%= escape_javascript(link_to t('auth.whoami', username: tmp_user().username), change_username_path, class: 'navbar-inverse navbar-brand', data: { remote: 'true', format: :js }) -%>")
# first unsubscripe old channels before subscribing new - TODO: check if faye handles thso orderly
for channel in Object.keys(window.commListeners)
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+Comm.Comm.channelCallBacksJSON[channel].channel_enc_key
  Comm.Comm.unsubscribeFrom channelPath, true
Comm.Comm.resetSystemContext <%= current_user.id -%>
