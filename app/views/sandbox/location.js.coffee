#
# TODO check if close is necessary and find a way to not reload bookmarks since they don't change
# bit later they are loaded from local anyway
#
APP._initPositionCB { coords: { latitude: <%= @location.latitude -%>, longitude: <%= @location.longitude -%> } }, "<%= @location.address -%>", true
if isMobile()
  $("#photo_nav_panel").panel("close")
else
  photoNavPanel.dialog("close")
APP.photoNav()
