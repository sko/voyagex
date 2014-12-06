class window.VoyageX.ClientState

  constructor: (view, uploadType, showCB, hideCB) ->
    @_views = { map: { key: 'map' }, chat: { key: 'chat' }, home: {  key: 'home', uploadType: uploadType } }
    @_showCB = showCB
    @_hideCB = hideCB
    @_currentViewKey = null # view
    this.setView @_views[view]
    #this.refreshView()

  currentView: () ->
    @_views[@_currentViewKey]
  
  getView: (view) ->
    @_views[view]

  getViews: () ->
    #Object.keys(window.commListeners).every (channel) ->
    console.log 'TODO'

  setView: (view) ->
    if @_currentViewKey == view.key
      return
    @_currentViewKey = view.key
    if view.key == 'home'
      @_views.home.uploadType = view.uploadType
    this.refreshView()

  refreshView: () ->
    for viewKey in Object.keys(@_views)
      if viewKey == @_currentViewKey
        @_showCB @_views[viewKey]
      else
        @_hideCB @_views[viewKey]

  linkForView: (path, lang, params) ->
    if path.indexOf('?') != -1
      path = path.substring(1).replace(/[cl]=[^&]*/, '')+'l=' + lang + '&c=' + @_currentViewKey
    else
      path = '?l=' + lang + '&c=' + @_currentViewKey
    if params != ''
      path += ('&'+params)
    path