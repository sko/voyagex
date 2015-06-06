<% if resource.errors.empty? %>
poi = eval('(' + '<%= poi_note_json[:poi].to_json.html_safe -%>' + ')')
poiNote = eval('(' + '<%= poi_note_json.to_json.html_safe -%>' + ')')
<%= window_prefix -%>Storage.Model.setupPoiForNote poi
<%= window_prefix -%>Storage.Model.instance().syncWithStorage poi, <%= window_prefix -%>APP.transfer().afterUploadPhoto, poiNote
<%= window_prefix -%>$("#upload_message").html('upload ok')
<% else %>
<%= window_prefix -%>$("#upload_error").html("<ul><%= escape_javascript(resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe) %></ul>")
<% end %>
<% if is_mobile %>
<%= window_prefix -%>$.mobile.loading("hide")
<% end %>
