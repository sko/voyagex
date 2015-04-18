#
# TODO check if close is necessary and find a way to not reload bookmarks since they don't change
# bit later they are loaded from local anyway
#
APP._initPositionCB { coords: { latitude: <%= @location.latitude -%>, longitude: <%= @location.longitude -%> } }, "<%= @location.address -%>", true
if isMobile()
  $("#context_nav_panel").panel("close")
else
  contextNavPanel.dialog("close")
APP.contextNav()
