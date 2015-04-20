<% if edit %>
  <% @_details = [:username]
     @_action = change_username_path
     @_user_name = tmp_user().username %>
  $('#whoami_edit').html("<%= j render('/users/edit_details') -%>")
<% else
  whoami = "<span class=\"whoami\">#{t('auth.whoami', username: tmp_user().username)}</span>".html_safe
  %>
  curU = <%= window_prefix -%>APP.user()
  curU.username = '<%= tmp_user().username -%>'
  APP.storage().saveCurrentUser curU
  APP.storage().saveUser { id: curU.id, username: curU.username }
  window.currentUser.username = '<%= tmp_user().username -%>'
  $('#whoami_edit').html("<%= escape_javascript(link_to whoami, change_username_path, class: 'navbar-inverse navbar-brand', data: { remote: 'true', format: :js })-%>")
<% end %>
