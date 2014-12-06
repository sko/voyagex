$('.login-link').each () ->
  $(this).css('display', 'block')
$('.reg-link').each () ->
  $(this).css('display', 'block')
$('.logout-link').each () ->
  $(this).css('display', 'none')
# you are always someone
$('.whoami').each () ->
  $(this).html("<%= escape_javascript(link_to t('auth.whoami', username: tmp_user().username), change_username_path, class: 'navbar-inverse navbar-brand', data: { remote: 'true', format: :js }) -%>")
for channel in Object.keys(window.commListeners)
  channelPath = '/'+channel
  unless window.VoyageX.USE_GLOBAL_SUBSCRIBE
    channelPath += VoyageX.PEER_CHANNEL_PREFIX+Comm.Comm.channelCallBacksJSON[channel].channel_enc_key
  Comm.Comm.unsubscribeFrom channelPath, true
Comm.Comm.resetSystemContext <%= tmp_user.id -%>
