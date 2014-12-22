<% if edit %>
  <% @_details = [:username]
     @_action = change_username_path
     @_user_name = tmp_user().username %>
  $('.whoami').html("<%= j render('/users/edit_details') -%>")
<% else %>
  APP._user.username = '<%= tmp_user().username -%>';
  $('.whoami').html("<%= escape_javascript(link_to t('auth.whoami', username: tmp_user().username), change_username_path, class: 'navbar-inverse navbar-brand', data: { remote: 'true', format: :js }) -%>")
<% end %>
