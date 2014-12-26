<% if resource.errors.empty? %>
poi = eval('(' + '<%= poi_note_json[:poi].to_json.html_safe -%>' + ')')
poiNote = eval('(' + '<%= poi_note_json.to_json.html_safe -%>' + ')')
<%= window_prefix -%>Storage.Model._syncWithStorage { poi: poi }, <%= window_prefix -%>afterUploadPhoto, poiNote, 0
<%= window_prefix -%>$("#upload_message").html('upload ok')
<% else %>
<%= window_prefix -%>$("#upload_error").html("<ul><%= escape_javascript(resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe) %></ul>")
<% end %>
<% if is_mobile %>
<%= window_prefix -%>$.mobile.loading("hide")
<% end %>
