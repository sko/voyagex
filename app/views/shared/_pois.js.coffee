<% @pois.each do |poi| %>
window.pois.push {id: <%= poi.id -%>,\
                  lat: <%= poi.location.latitude -%>,\
                  lng: <%= poi.location.longitude -%>,\
                  address: '<%= poi.location.address -%>' }
<% end %>
