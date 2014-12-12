class window.VoyageX.NavBar
  @menuNavClick: (clickSrc) ->
    window.clientState.setView(window.clientState.getView(clickSrc))
    VoyageX.Main.map().invalidateSize({
              reset: true,
              pan: false,
              animate: false
            })
    return false

  @showView: (view) ->
    $('#content_'+view.key).css('display', 'block')
    if view.key == 'home'
      switch view.uploadType
        when 'camera'
          $('button[value=camera]').focus()
        when 'file'
          $('button[value=file]').focus()    
  @hideView: (view) ->
    $('#content_'+view.key).css('display', 'none')

window.clientState = new VoyageX.ClientState('map', 'camera', VoyageX.NavBar.showView, VoyageX.NavBar.hideView)

$(document).on 'click', '.activate_chat', (event) ->
  VoyageX.NavBar.menuNavClick('chat')
  if $('#nav_chat_popup-popup').hasClass('ui-popup-active')
    $('#nav_chat_popup-popup').removeClass('ui-popup-active').addClass('ui-popup-hidden')

$(document).on 'click', '.activate_map', (event) ->
  VoyageX.NavBar.menuNavClick('map')

$(document).on 'click', '.activate_upload', (event) ->
  VoyageX.NavBar.menuNavClick('home')
