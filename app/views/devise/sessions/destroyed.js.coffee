$('.login-link').each () ->
  $(this).css('display', 'block')
$('.reg-link').each () ->
  $(this).css('display', 'block')
$('.logout-link').each () ->
  $(this).css('display', 'none')
# you are always someone
$('.whoami').each () ->
  $(this).html("<%= escape_javascript(t('auth.whoami', username: tmp_user().username)) -%>")