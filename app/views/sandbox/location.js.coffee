APP._initPositionCB { coords: { latitude: <%= @location.latitude -%>, longitude: <%= @location.longitude -%> } }, "<%= @location.address -%>", true
if isMobile()
  $("#photo_nav_panel").panel("close")
else
  photoNavPanel.dialog("close")
APP.photoNav()
