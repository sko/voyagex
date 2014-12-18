<% if is_mobile -%>
$.mobile.loading("hide")
<% end -%>
<% if @upload.errors.empty? -%>
<% if is_mobile -%>
$("#upload_data_panel").panel("close")
<% else -%>
uploadDataDialog.dialog("close")
<% end -%>
eval("<%= j render(partial: 'shared/upload_comments') -%>")
<% else -%>
$("#upload_error").html("<ul><%= escape_javascript(@upload.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe) %></ul>")
<% end -%>
