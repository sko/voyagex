$('.login-link').each () ->
  $(this).css('display', 'block')
$('.reg-link').each () ->
  $(this).css('display', 'block')
$('.logout-link').each () ->
  $(this).css('display', 'none')
# you are always someone
$('.whoami').each () ->
  $(this).html("<%= escape_javascript(link_to t('auth.whoami', username: tmp_user().username), change_username_path, class: 'navbar-inverse navbar-brand', data: { remote: 'true', format: :js }) -%>")