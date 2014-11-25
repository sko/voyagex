<% if resource.errors.empty? -%>
$("#upload_message").html('upload ok')
<% else -%>
$("#upload_error").html("<ul><%= escape_javascript(resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe) %></ul>")
<% end -%>
<% if is_mobile %>
$.mobile.loading("hide")
<% end %>
<%
#max_width = 100.0
#geometry = Paperclip::Geometry.from_file(@upload.file)
#width = geometry.width.to_i
#tag = image_tag(@upload.file.url, style: "width:#{(width*(max_width/width)).to_i}px;")
%>
#$("#upload_preview").prepend("<%= tag.gsub(/"/, '\'').html_safe -%>");
$('#media_input_container').css('display', 'none')
