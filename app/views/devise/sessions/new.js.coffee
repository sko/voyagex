<% unless resource.errors.empty? -%>
$("#sign_in_error").html("<ul><%= escape_javascript(resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe) %></ul>")
<% end -%>
$("#sign_in_modal").dialog('open')