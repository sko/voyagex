#
# tile-length in meters:
# map.containerPointToLatLng(L.point(0,0)).distanceTo(map.containerPointToLatLng(L.point(0,256)))
#
class window.VoyageX.MapControl

  @_SINGLETON = null
#  @_COUNT = 0

  # zooms msut be sorted from lowest (f.ex. 1) to highest (f.ex. 16)
  constructor: (cacheStrategy, mapOptions, offlineZooms) ->
    MapControl._SINGLETON = this
    window.MC = this
    mapOptions.layers = [new L.TileLayer.Functional(VoyageX.MapControl.drawTile, {
        subdomains: mapOptions.subdomains
      })]
    @_mapOptions = mapOptions
    @_cacheStrategy = cacheStrategy
    @_zooms = mapOptions.zooms
    @_minZoom = @_zooms[0]
    @_maxZoom = @_zooms[@_zooms.length - 1]
    @_offlineZooms = offlineZooms
    @_numTilesCached = 0
    @_tileImageContentType = 'image/webp'
    #@_tileImageContentType = 'image/png'
    #@_tileLoadQueue = []
    @_tileLoadQueue = {}
    @_saveCallsToFlushCount = 0
    @_map = new L.Map('map', mapOptions)
    @_map.whenReady () ->
        console.log '### map-event: ready ...'
        #MapControl.instance().showTileInfo()
        if APP.isOnline()
          mC = VoyageX.MapControl.instance()
          unless Comm.StorageController.isFileBased()
            x = parseInt(mC._map.project(mC._map.getCenter()).x/256)
            y = parseInt(mC._map.project(mC._map.getCenter()).y/256)
            view = {zoom: mC._map.getZoom(), tile: {column: x, row: y}, subdomain: mC._mapOptions.subdomains[0]}
            mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS
#        #for e, idx in mC._tileLoadQueue
#        for xY in Object.keys(mC._tileLoadQueue)
#        #while (e = mC._tileLoadQueue.pop())?
#          console.log '### map-event: tileKey = '+mC._tileLoadQueue[xY].xYZ
#          #view = {zoom: e.xYZ[2], tile: {column: e.xYZ[0], row: e.xYZ[1]}, subdomain: e.viewSubdomain}
#          #mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS, e.deferredModeParams
    @_map.on 'moveend', (event) ->
        console.log '### map-event: moveend ...'
        #MapControl.instance().showTileInfo()
        if APP.isOnline()
          mC = VoyageX.MapControl.instance()
          unless Comm.StorageController.isFileBased()
            x = parseInt(mC._map.project(mC._map.getCenter()).x/256)
            y = parseInt(mC._map.project(mC._map.getCenter()).y/256)
            view = {zoom: mC._map.getZoom(), tile: {column: x, row: y}, subdomain: mC._mapOptions.subdomains[0]}
            mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS
#        #for e, idx in mC._tileLoadQueue
#        for xY in Object.keys(mC._tileLoadQueue)
#        #while (e = mC._tileLoadQueue.pop())?
#          console.log '### map-event: tileKey = '+mC._tileLoadQueue[xY].xYZ
#          #view = {zoom: e.xYZ[2], tile: {column: e.xYZ[0], row: e.xYZ[1]}, subdomain: e.viewSubdomain}
#          #mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS, e.deferredModeParams
    @_map.on('zoomend', (e) ->
        console.log '### map-event: zoomend ...'
        APP._zoomEnd(e);
      )
    @_map.on 'click', (event) ->
      address = null
      APP._setSelectedPositionLatLng VoyageX.Main.markerManager().get()||VoyageX.Main.markerManager().add({lat: event.latlng.lat, lng: event.latlng.lng}, VoyageX.Main._markerEventsCB, true), event.latlng.lat, event.latlng.lng, address
      APP.publishPosition()

  map: () ->
    @_map

  # google z/x/y
  # x ... parseInt(map.project(map.getCenter()).x/256)
  #
  # c = map.project(map.getCenter())
  # map.unproject(L.point(c.x+256, c.y), 15) == map.unproject(L.point(c.x*2+512, c.y*2), 16)
  #
  # for all zoomLevels z this is the same point
  # map.unproject(L.point(c.x*Math.pow(2, z-map.getZoom()), c.y*Math.pow(2, z-map.getZoom())), z-1)
  #
  # TODO: 
  #    @_map.containerPointToLatLng(L.point(0,0)).distanceTo(@_map.containerPointToLatLng(L.point(0,256)))
  tileWidthToMeters: (zoomLevel) ->
    # in 0 zoomLevel there is 1 single tile and the L.latLng(0,0) is in the center 
    tileWidth = @_map.project(L.latLng(0,0), 0).x * 2
#    # calculate lng-diff in current-zoom-level
#    relOrds = @_map.latLngToContainerPoint(L.latLng(0,0))
#    lngDiffPerTile = map.containerPointToLatLng(L.point(relOrds.x+tileWidth,relOrds.y)).lng

#    p1 = L.point(c.x*Math.pow(2, z-map.getZoom()), c.y*Math.pow(2, z-map.getZoom()))
#    p2 = L.point(c.x*Math.pow(2, z-map.getZoom())+tileWidth, c.y*Math.pow(2, z-map.getZoom()))
#    widthInMeters = map.unproject(p1).distanceTo(map.unproject(p2))

#    #lngDiffPerTile = map.containerPointToLatLng(L.point(relOrds.x+tileWidth/(map.getZoom()+1),relOrds.y)).lng
    curWidthInMeters = @_map.containerPointToLatLng(L.point(0,0)).distanceTo(@_map.containerPointToLatLng(L.point(tileWidth, 0)))
    scaleFactor = @_map.getZoom() - zoomLevel
    curWidthInMeters * Math.pow(2, scaleFactor)

  curTileWidthToMeters: () ->
    this.tileWidthToMeters(@_map.getZoom())
  
  showTileInfo: () ->
    tiles = $('#map > .leaflet-map-pane > .leaflet-tile-pane .leaflet-tile-container:parent > .leaflet-tile')
    remove = tiles.first().parent().children('div[data-role=tileInfo]')
    if remove.length >= 1
      remove.remove()
    else
      for tile, idx in tiles
        style = $(tile).attr('style')
        #key = $(tile).attr('src').match(/[0-9]+\/[0-9]+\/[0-9]+$/)
        xOff = parseInt(style.match(/left:(.+?)px/)[1].trim())+1
        yOff = parseInt(style.match(/top:(.+?)px/)[1].trim())+1
        latLngOff = @_map.unproject L.point((@_map.getPixelOrigin().x+xOff), (@_map.getPixelOrigin().y+yOff))
        x = parseInt(@_map.project(latLngOff).x/256)
        y = parseInt(@_map.project(latLngOff).y/256)
        key = @_map.getZoom()+' / '+x+' / '+y
        $(tile).after('<div data-role="tileInfo" style="position: absolute; '+style+' z-index: 9999; opacity: 0.8; text-align: center; vertical-align: middle; border: 1px solid red; color: red; font-weight: bold;">'+key+'</div>')

  @instance: () ->
    @_SINGLETON

  @toUrl: (xYZ, viewSubdomain) ->
    VoyageX.TILE_URL_TEMPLATE
      .replace('{z}', xYZ[2])
      .replace('{y}', xYZ[1])
      .replace('{x}', xYZ[0])
      .replace('{s}', viewSubdomain)

  # plugged in via https://github.com/ismyrnow/Leaflet.functionaltilelayer
  @drawTile: (view) ->
#    MapControl._COUNT += 1
#    unless MapControl._COUNT <= 2
#      return VoyageX.TILE_URL_TEMPLATE.replace('{z}', view.zoom).replace('{y}', view.tile.row).replace('{x}', view.tile.column).replace('{s}', view.subdomain)
    mC = VoyageX.MapControl.instance()
    storeKey = Comm.StorageController.tileKey([view.tile.column, view.tile.row, view.zoom])
    console.log 'drawTile - ........................................'+storeKey
    if Comm.StorageController.isFileBased()
      # use File-API
      # TODO ? maybe just query offline-zoom-files - see MapControl.tileUrl else of if view.zoom in mC._offlineZooms
      # NO - because other zoom-levels may trigger some extra-action (liek prefetch ...)
      deferredModeParams = { mC: mC,\
                             view: view,\
                             prefetchZoomLevels: true,\
                             save: true,\
                             fileStatusCB: MapControl._fileStatusDeferred,\
                             deferred: $.Deferred(),\
                             promise: null }
      Comm.StorageController.instance().getTile [view.tile.column, view.tile.row, view.zoom], deferredModeParams
      deferredModeParams.promise
    else
      # use localStorage
      stored = if view.zoom in mC._offlineZooms then Comm.StorageController.instance().getTile [view.tile.column, view.tile.row, view.zoom] else null
      unless stored?
        VoyageX.MapControl.tileUrl mC, view
      else
        console.log 'using cached tile: '+storeKey
        stored

  @tileUrl: (mC, view, deferredModeParams = null) ->
    tileUrl = VoyageX.TILE_URL_TEMPLATE
              .replace('{z}', view.zoom)
              .replace('{y}', view.tile.row)
              .replace('{x}', view.tile.column)
              .replace('{s}', view.subdomain)
    if APP.isOnline()
      # if current zoom-level is not offline-zoom-level then load from web
      if view.zoom in mC._offlineZooms
        if deferredModeParams != null
          deferredModeParams.tileUrl = tileUrl
        # _map maybe not ready on very first call
        #if mC._map?
        #  readyImage = mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS, deferredModeParams
        #else
        #  readyImage = MapControl.loadAndPrefetch mC, [view.tile.column, view.tile.row, view.zoom], view.subdomain, deferredModeParams
        readyImage = MapControl.loadAndPrefetch mC, [view.tile.column, view.tile.row, view.zoom], view.subdomain, deferredModeParams
        # next is in map-event-handlers ready, onmovend
        #unless Comm.StorageController.isFileBased() || !mC._map?
        #  mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS, deferredModeParams
      else
        readyImage = tileUrl
        if deferredModeParams != null
          #deferredModeParams.tileUrl = tileUrl
          Comm.StorageController.instance().resolveOnlineNotInOfflineZooms tileUrl, deferredModeParams
        mC._prefetchZoomLevels [view.tile.column, view.tile.row, view.zoom], view.subdomain, deferredModeParams
      readyImage
    else
      readyImage = mC._notInCacheImage $('#tile_canvas')[0], view.tile.column, view.tile.row, view.zoom
      if deferredModeParams != null
        Comm.StorageController.instance().resolveOfflineNotInCache readyImage, deferredModeParams
      readyImage

  @_fileStatusDeferred: (deferredModeParams, created) ->
    xYZ = [deferredModeParams.view.tile.column, deferredModeParams.view.tile.row, deferredModeParams.view.zoom]
    console.log 'fileStatusCB (created = '+created+'): xYZ = '+xYZ
    mC = deferredModeParams.mC
    if created
      #if xYZ.toString() == mC._tileLoadQueue[0].xYZ.toString()
      #if mC._saveCallsToFlushCount == mC._tileLoadQueue.length
      tilesToSaveKeys = Object.keys(mC._tileLoadQueue)
      if mC._saveCallsToFlushCount == tilesToSaveKeys.length
        mC._saveCallsToFlushCount = 0
#        #sorted = Object.keys(mC._tileLoadQueue)
#        mC._tileLoadQueue = mC._tileLoadQueue.sort (a, b) ->
#          if a.xYZ[0] > b.xYZ[0]
#            -1
#          else if a.xYZ[0] == b.xYZ[0]
#            if a.xYZ[1] > b.xYZ[1]
#              -1
#            else
#              1
#          else
#            1
        #for idx in [mC._tileLoadQueue-1..0]
        for xY in Object.keys(mC._tileLoadQueue)
        #while (e = mC._tileLoadQueue.pop())?
          #console.log '### _fileStatusDeferred: prefetching area for tileKey = '+e.xYZ
          e = mC._tileLoadQueue[xY]
          #view = {zoom: e.xYZ[2], tile: {column: e.xYZ[0], row: e.xYZ[1]}, subdomain: e.viewSubdomain}
          x = parseInt(mC._map.project(mC._map.getCenter()).x/256)
          y = parseInt(mC._map.project(mC._map.getCenter()).y/256)
          view = {zoom: mC._map.getZoom(), tile: {column: x, row: y}, subdomain: e.viewSubdomain}
          #delete e.deferredModeParams.fileStatusCB
          mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS, e.deferredModeParams
        mC._tileLoadQueue = {}
    else
      #for e, idx in mC._tileLoadQueue
      for xY in Object.keys(mC._tileLoadQueue)
        e = mC._tileLoadQueue[xY]
        if e.xYZ.toString() == xYZ.toString()
          #console.log '### _fileStatusDeferred: removing tileKey = '+e.xYZ
          console.log '### _fileStatusDeferred: removing tileKey = '+e.xYZ
          #mC._tileLoadQueue.splice idx, 1
          delete mC._tileLoadQueue[xY]
          mc._saveCallsToFlushCount -= 1
          break
 
  @loadAndPrefetch: (mC, xYZ, viewSubdomain, deferredModeParams = null) ->
    if Comm.StorageController.isFileBased()
      #mC._tileLoadQueue.splice(0, 0, {xYZ: xYZ, viewSubdomain: viewSubdomain, deferredModeParams: deferredModeParams})
      mC._tileLoadQueue[xYZ[0]+'_'+xYZ[1]] = {xYZ: xYZ, viewSubdomain: viewSubdomain, deferredModeParams: deferredModeParams}
      mC._saveCallsToFlushCount += 1
    readyImage = mC.loadReadyImage MapControl.toUrl(xYZ, viewSubdomain), xYZ, deferredModeParams
    if deferredModeParams == null || deferredModeParams.prefetchZoomLevels
      unless deferredModeParams == null
        deferredModeParams.prefetchZoomLevels = false
      mC._prefetchZoomLevels xYZ, viewSubdomain, deferredModeParams
    readyImage

  @notInCacheImage: (x, y, z) ->
    mC = VoyageX.MapControl.instance()
    mC._notInCacheImage $('#tile_canvas')[0], x, y, z

  _prefetchZoomLevels: (xYZ, viewSubdomain, deferredModeParams = null) ->
    storeKey = Comm.StorageController.tileKey([xYZ[0], xYZ[1], xYZ[2]])
    # store 1 higher zoomlevel if current zoomlevel is not in @_offlineZooms
    for z in @_offlineZooms
      if z > xYZ[2]
        console.log 'prefetch-base: '+storeKey
        this._prefetchHigherZoomLevel xYZ, (z-xYZ[2]-1)
        break
    # store all tiles in <= zoom-levels
    # 4 small tiles become one bigger tile
    this._prefetchLowerZoomLevels xYZ, viewSubdomain, deferredModeParams

  _prefetchArea: (view, radiusMeters, deferredModeParams = null) ->
    xYZ = [view.tile.column, view.tile.row, view.zoom]
#    centerTile = null
    console.log 'area-prefetch-base: '+Comm.StorageController.tileKey([xYZ[0], xYZ[1], xYZ[2]])
    curTileWidthMeters = this.curTileWidthToMeters()
    numTilesLeft = 0
    while radiusMeters - curTileWidthMeters > 0
      numTilesLeft += 1
      radiusMeters -= curTileWidthMeters
    for addToX in [-numTilesLeft..numTilesLeft]
      for addToY in [-numTilesLeft..numTilesLeft]
        curXYZ = [xYZ[0]+addToX,
                  xYZ[1]+addToY,
                  xYZ[2]]
        # condition only required if Comm.StorageController.isFileBased()
        unless @_tileLoadQueue[curXYZ[0]+'_'+curXYZ[1]]
          storeKey = Comm.StorageController.tileKey([curXYZ[0], curXYZ[1], curXYZ[2]])
          if Comm.StorageController.isFileBased()
            prefetchParams = { loadTileDataCB: this.loadReadyImage,\
                               mC: this,\
                               view: deferredModeParams.view,\
                               xYZ: curXYZ,\
                               tileUrl: MapControl.toUrl(curXYZ, view.subdomain),\
                               prefetchZoomLevels: true,\
                               save: true,\
                               deferred: deferredModeParams.deferred,\
                               promise: deferredModeParams.promise }
            if addToX == 0 and addToY == 0
              Comm.StorageController.instance().loadAndPrefetchTile prefetchParams
            else
              Comm.StorageController.instance().prefetchTile prefetchParams
          else
            #@_tileLoadQueue[curXYZ[0]+'_'+curXYZ[1]] = {xYZ: curXYZ, viewSubdomain: view.subdomain, deferredModeParams: deferredModeParams}
            stored = Comm.StorageController.instance().getTile curXYZ, deferredModeParams
           #unless stored? && (deferredModeParams==null || !deferredModeParams.loadAndPrefetch?)
            unless stored?
              console.log 'prefetching area tile: '+storeKey
              readyImage = MapControl.loadAndPrefetch MapControl.instance(), curXYZ, view.subdomain, deferredModeParams
#              if addToX == 0 and addToY == 0
#                centerTile = readyImage
#            else
              #console.log 'area tile already cached: '+storeKey
#              if addToX == 0 and addToY == 0
#                centerTile = stored
#    centerTile

  # fetch all tiles for next higher zoom-level.
  # 1 level difference -> 4 tiles, 2 level -> 16, ...
  # left: startingZoomLevel - nextHigherOfflineZoomLevel
  # levelDiffLimit: max num of higher zoom-levels to check
  # depth: internal recursion counter
  _prefetchHigherZoomLevel: (xYZ, viewSubdomain, left, levelDiffLimit = 1, depth = 1) ->
    for addToX in [0,1]
      for addToY in [0,1]
        curXYZ = [xYZ[0]*2+addToX,
                  xYZ[1]*2+addToY,
                  xYZ[2]+1]
        if left >= 1 && depth < levelDiffLimit
          this._prefetchHigherZoomLevel curXYZ, (left-1), levelDiffLimit, (depth+1)
        if curXYZ[2] in @_offlineZooms
          curStoreKey = curXYZ[2]+'/'+curXYZ[0]+'/'+curXYZ[1]
          console.log 'TODO: prefetch higher zoom tile: '+curStoreKey

  _prefetchLowerZoomLevels: (curXYZ, viewSubdomain, deferredModeParams = null) ->
    for n in [(curXYZ[2]-1)..@_minZoom]
      curXYZ = [Math.round((curXYZ[0]-0.1)/2),
                Math.round((curXYZ[1]-0.1)/2),
                n]
      if n in @_offlineZooms
        parentStoreKey = Comm.StorageController.tileKey([curXYZ[0], curXYZ[1], curXYZ[2]])
        if Comm.StorageController.isFileBased()
          prefetchParams = { loadTileDataCB: this.loadReadyImage,\
                             mC: this,\
                             view: deferredModeParams.view,\
                             xYZ: curXYZ,\
                             tileUrl: MapControl.toUrl(curXYZ, viewSubdomain),\
                             deferred: $.Deferred() }
          Comm.StorageController.instance().prefetchTile prefetchParams
        else
          stored = Comm.StorageController.instance().getTile curXYZ, deferredModeParams
          unless stored?
            parentTileUrl = MapControl.toUrl(curXYZ, viewSubdomain)
            console.log 'prefetching lower-zoom tile: '+parentStoreKey
            readyImage = this.loadReadyImage parentTileUrl, curXYZ, deferredModeParams

  # has to be done sequentially becaus we're using one canvas for all
  loadReadyImage: (imgUrl, xYZ, deferredModeParams = null) ->
    if deferredModeParams == null
      promise = true
      deferred = $.Deferred()
    img = new Image
    img.crossOrigin = ''
    mC = this
    img.onload = (event) ->
      base64ImgDataUrl = mC._toBase64 $('#tile_canvas')[0], this # event.target
      unless Comm.StorageController.isFileBased()
        Comm.StorageController.instance().storeImage xYZ, base64ImgDataUrl, deferredModeParams
        cacheStats()
      else
        if Comm.StorageController.instance()._storedFilesAreBase64
          Comm.StorageController.instance().storeImage xYZ, base64ImgDataUrl, deferredModeParams
        else
          $('#tile_canvas')[0].toBlob((blob) ->
              Comm.StorageController.instance().storeImage xYZ, blob, deferredModeParams
            )
      if promise
        deferred.resolve(base64ImgDataUrl)
    if promise
      readyImg = deferred.promise()
      img.src = imgUrl
      # this.loadReadyImage stores Tiles asynchronously so we set empty-tile here to prevent multi-fetch
      Comm.StorageController.instance().storeTile xYZ, null, readyImg, deferredModeParams
      readyImg
    else
      img.src = imgUrl
      null

  _toBase64: (canvas, image) ->
    canvas.width = 256
    canvas.height = 256
    context = canvas.getContext('2d')
    context.drawImage(image, 0, 0)
    canvas.toDataURL(@_tileImageContentType)

  _notInCacheImage: (canvas, x, y, z) ->
    canvas.width = 256
    canvas.height = 256
    context = canvas.getContext('2d')
    context.fillStyle = "black";
    context.fillRect(0,0,256,256);
    context.fillStyle = "white";
    context.fillRect(1,1,254,254);
    context.fillStyle = "blue";
    context.font = "bold 16px Arial";
    context.fillText("Not Cached", 100, 80);
    context.fillText(z+' / '+x+' / '+y, 40, 110);
    canvas.toDataURL(@_tileImageContentType)
