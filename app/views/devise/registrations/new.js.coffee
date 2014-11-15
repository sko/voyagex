<% unless resource.errors.empty? -%>
$("#sign_up_error").html("<ul><%= escape_javascript(resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe) %></ul>")
<% end -%>
$("#sign_up_modal").dialog('open')