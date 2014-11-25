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
  $(this).html("<%= escape_javascript(link_to t('auth.whoami', username: tmp_user().username), change_username_path, class: "btn", data: { remote: "true", format: :js }) -%>")
