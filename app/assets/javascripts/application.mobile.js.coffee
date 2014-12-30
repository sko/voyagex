class window.VoyageX.NavBar
  @_orientationDims = { portrait: [], landscape: [] }
  @_checkDims = {o: null, w: -1, h: -1}
  @menuNavClick: (clickSrc) ->
    window.clientState.setView(window.clientState.getView(clickSrc))
    APP.map().invalidateSize({
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

  @orientationChanged: (event) -> 
    # event.orientation = portrait | landscape
    if VoyageX.NavBar._orientationDims[event.orientation].length == 0
      VoyageX.NavBar._checkDims.o = event.orientation
      VoyageX.NavBar._checkDims.w = $(window).width()
      VoyageX.NavBar._checkDims.h = $(window).height()
      VoyageX.NavBar._checkDims.n = 1
      setTimeout('checkDims()', 500)
    else
      #if $('#photo_nav_panel').hasClass('ui-panel-open')
      console.log 'orientationchange: to '+event.orientation+'; window-width = '+$(window).width()+', stored-width = '+NavBar._orientationDims[event.orientation][0]
      #console.log 'body-width = '+$('body').width()+'; body-height = '+$('body').height()
      $('#photo_nav_panel').css('width', NavBar._orientationDims[event.orientation][0])
      $('#photo_nav_panel').css('height', NavBar._orientationDims[event.orientation][1]-$('#photo_nav_panel').offset().top)
      $('#map').css('width', NavBar._orientationDims[event.orientation][0])
      $('#map').css('height', NavBar._orientationDims[event.orientation][1]-$('#map').offset().top)
      APP.map().invalidateSize({
          reset: true,
          pan: false,
          animate: false
        })

window.clientState = new VoyageX.ClientState('map', 'camera', VoyageX.NavBar.showView, VoyageX.NavBar.hideView)

$(document).on 'click', '.activate_map', (event) ->
  VoyageX.NavBar.menuNavClick('map')

$(document).on 'click', '.activate_upload', (event) ->
  VoyageX.NavBar.menuNavClick('home')

$("#photo_nav_tabs").tabs()

window.checkDims = () ->
  console.log 'checkDims: state.w = '+VoyageX.NavBar._checkDims.w+', w.width = '+$(window).width()+', state.h = '+VoyageX.NavBar._checkDims.h+', w.height = '+$(window).height()
  if VoyageX.NavBar._checkDims.n <= 2
    if VoyageX.NavBar._checkDims.w == $(window).width() || VoyageX.NavBar._checkDims.h == $(window).height()
      VoyageX.NavBar._checkDims.n += 1
      setTimeout('checkDims()', 500)
      return null
  VoyageX.NavBar._orientationDims[VoyageX.NavBar._checkDims.o][0] = $(window).width()
  VoyageX.NavBar._orientationDims[VoyageX.NavBar._checkDims.o][1] = $(window).height()
  VoyageX.NavBar.orientationChanged {orientation: VoyageX.NavBar._checkDims.o}

$(window).on('orientationchange', VoyageX.NavBar.orientationChanged)

#window.hideAddressBar = () ->
#  if(!window.location.hash)
#    if(document.height < window.outerHeight)
#        document.body.style.height = (window.outerHeight + 50) + 'px'
#    setTimeout(() ->
#        window.scrollTo(0, 1)
#    , 50)
# Main.onload 
#window.addEventListener("load", () ->
#    if(!window.pageYOffset)
#      hideAddressBar()
#  )
#window.addEventListener("orientationchange", hideAddressBar)