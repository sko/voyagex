<% if edit %>
  <% @_details = [:username]
     @_action = change_username_path %>
  $('.whoami').html("<%= j render('/users/edit_details') -%>")
<% else %>
  $('.whoami').html("<%= escape_javascript(link_to t('auth.whoami', username: tmp_user().username), change_username_path, class: "btn", data: { remote: "true", format: :js }) -%>")
<% end %>
