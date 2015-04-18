#
# tile-length in meters:
# map.containerPointToLatLng(L.point(0,0)).distanceTo(map.containerPointToLatLng(L.point(0,256)))
#
class window.VoyageX.MapControl

  @_SINGLETON = null

  # zooms msut be sorted from lowest (f.ex. 1) to highest (f.ex. 16)
  constructor: (mapOptions, offlineZooms, tileHandler = null) ->
    unless tileHandler?
      tileHandler = new L.TileLayer.Functional(VoyageX.MapControl.drawTile, {
          subdomains: mapOptions.subdomains
        })
    MapControl._SINGLETON = this
    window.MC = this
    mapOptions.layers = [tileHandler]
    @_mapOptions = mapOptions
    @_zooms = mapOptions.zooms
    @_minZoom = @_zooms[0]
    @_maxZoom = @_zooms[@_zooms.length - 1]
    @_offlineZooms = offlineZooms
    @_numTilesCached = 0
    @_tileImageContentType = 'image/webp'
    #@_tileImageContentType = 'image/png'
    #@_tileLoadQueue = []
    @_tileLoadQueue = {}
    @_cacheMissTiles = []
    @_saveCallsToFlushCount = 0
    @_showTileInfo = false
    @_pathViewIds = {}
    @_map = new L.Map('map', mapOptions)
    @_map.whenReady () ->
        console.log '### map-event: ready ...'
        #MapControl.instance().showTileInfo false
        #for poi in APP._initPoisOnMap
        #  marker = Main.markerManager().add poi.location, VoyageX.Main._markerEventsCB, false
        if APP.isOnline()
          unless Comm.StorageController.isFileBased()
            x = parseInt(MC._map.project(MC._map.getCenter()).x/256)
            y = parseInt(MC._map.project(MC._map.getCenter()).y/256)
            view = {zoom: MC._map.getZoom(), tile: {column: x, row: y}, subdomain: MC._mapOptions.subdomains[0]}
            MC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS
    @_map.on 'moveend', (event) ->
        console.log '### map-event: moveend ...'
        if MapControl.instance()._showTileInfo
          MapControl.instance().showTileInfo false
        if APP.isOnline()
          unless Comm.StorageController.isFileBased()
            x = parseInt(MC._map.project(MC._map.getCenter()).x/256)
            y = parseInt(MC._map.project(MC._map.getCenter()).y/256)
            view = {zoom: MC._map.getZoom(), tile: {column: x, row: y}, subdomain: MC._mapOptions.subdomains[0]}
            MC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS
        posLatLng = VoyageX.MapControl.instance()._map.getCenter()
        #position = {coords: {latitude: posLatLng.lat, longitude: posLatLng.lng}}
        #APP._initPositionCB(position, null, true)
        APP.showPOIs posLatLng
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

  reload: () ->
##    min = APP.map().getPixelBounds().min
##    newBounds = L.bounds min, L.point(min.x+$('#map').width(), min.y+$('#map').height())
#    APP.map().fitBounds L.latLngBounds(APP.map().unproject(newBounds.min), APP.map().unproject(newBounds.max))
    MC.map().invalidateSize({
        reset: false,
        pan: false,
        animate: false
      })

  tileLengthToMeters: (zoomLevel) ->
    # in 0 zoomLevel there is 1 single tile and the L.latLng(0,0) is in the center 
    tileWidth = @_map.project(L.latLng(0,0), 0).x * 2
    curWidthInMeters = @_map.containerPointToLatLng(L.point(0,0)).distanceTo(@_map.containerPointToLatLng(L.point(tileWidth, 0)))
    scaleFactor = @_map.getZoom() - zoomLevel
    curWidthInMeters * Math.pow(2, scaleFactor)

  curTileWidthToMeters: () ->
    this.tileLengthToMeters(@_map.getZoom())

  tileForPosition: (lat, lng, zoom) ->
    curLatlng = L.latLng(lat, lng)
    curTileZ = @_map.getZoom()
    p = @_map.project(curLatlng, zoom)
    curLatX = p.x
    curLatY = p.y
    curTileX = parseInt curLatX/256
    curTileY = parseInt curLatY/256
    {x: curTileX, y: curTileY, latX: curLatX, latY: curLatY}

  _eachTile: (callback, clearOnly) ->
    tiles = $('#map > .leaflet-map-pane > .leaflet-tile-pane .leaflet-tile-container:parent > .leaflet-tile')
    remove = tiles.first().parent().children('div[data-role=tileInfo]')
    remove.remove()
    unless clearOnly
      for tile, idx in tiles
        style = $(tile).attr('style')
        #key = $(tile).attr('src').match(/[0-9]+\/[0-9]+\/[0-9]+$/)
        xMatch = style.match(/left:(.+?)px/)
        if xMatch?
          xOff = parseInt(xMatch[1].trim())+1
          yOff = parseInt(style.match(/top:(.+?)px/)[1].trim())+1
        else
          xOff = parseInt(style.match(/translate\((.+?)px/)[1].trim())+1
          yOff = parseInt(style.match(/translate\(.+?,(.+?)px/)[1].trim())+1
        callback xOff, yOff, tile, style

  _drawTileInfo: (x, y, z, style, tileSelector, withBackground = false) ->
    key = z+' / '+x+' / '+y
    if withBackground
      style += ' background-color: green;'
      color = 'blue'
    else
      color = 'red'
    tileSelector.after('<div data-role="tileInfo" style="position: absolute; '+style+' z-index: 9999; opacity: 0.5; text-align: center; vertical-align: middle; border: 1px solid '+color+'; color: '+color+'; font-weight: bold;">'+key+'</div>')

  showSelTileInfo: (tiles, zoom) ->
    tileInfos = []
    pixelOrigin = APP.map().getPixelOrigin()
    ((tileInfos, pixelOrigin) ->
        VoyageX.Main._MAP_CONTROL._eachTile (xOff, yOff, tile, style) ->
            for t, idx in tiles
              if t.x*256 <= pixelOrigin.x+xOff <= ((t.x+1)*256) 
                if t.y*256 <= pixelOrigin.y+yOff <= ((t.y+1)*256)
                  #VoyageX.Main._MAP_CONTROL._drawTileInfo t.x, t.y, zoom, style, $(tile)
                  tileInfos.push {x: t.x, y: t.y, z: zoom, s: style, tS: $(tile)}
          , false
    )(tileInfos, pixelOrigin)
    ts = $('#map > .leaflet-map-pane > .leaflet-tile-pane .leaflet-tile-container:parent > .leaflet-tile')
    remove = ts.first().parent().children('div[data-role=tileInfo]')
    remove.remove()
    for tI in tileInfos
      VoyageX.Main._MAP_CONTROL._drawTileInfo tI.x, tI.y, tI.z, tI.s, tI.tS, true

  showTileInfo: (set = true) ->
    if set
      @_showTileInfo = !@_showTileInfo
    this._eachTile (xOff, yOff, tile, style) ->
        latLngOff = APP.map().unproject L.point((APP.map().getPixelOrigin().x+xOff), (APP.map().getPixelOrigin().y+yOff))
        x = parseInt(APP.map().project(latLngOff).x/256)
        y = parseInt(APP.map().project(latLngOff).y/256)
        VoyageX.Main._MAP_CONTROL._drawTileInfo x, y, APP.map().getZoom(), style, $(tile)
      , (!@_showTileInfo)

  drawPath: (user, path, append = false) ->
    pathKey = APP.storage().pathKey path
    unless @_pathViewIds.pathKey?
      @_pathViewIds[pathKey] = []
    if append
      if path.length >= 2
        last = path[path.length-2]
        current = path[path.length-1]
        polyline = L.polyline([L.latLng(last.lat, last.lng), L.latLng(current.lat, current.lng)], {color: 'red'}).addTo(@_map)
        pathViewId = polyline._container.innerHTML.match(/d="([^"]+)/)[1]
        @_pathViewIds[pathKey].push pathViewId
    else
      for entry, idx in path
        unless idx >= 1
          continue
        curPolyline = L.polyline([L.latLng(path[idx-1].lat, path[idx-1].lng), L.latLng(entry.lat, entry.lng)], {color: 'red'}).addTo(@_map)
        pathViewId = curPolyline._container.innerHTML.match(/d="([^"]+)/)[1]
        @_pathViewIds[pathKey].push pathViewId
  
  hidePath: (pathKey) ->
    #pathKey = APP.storage().pathKey path
    for pathViewId in @_pathViewIds[pathKey]
      $('path[d="'+pathViewId+'"]').closest('g').remove()

  @instance: () ->
    @_SINGLETON

  @toUrl: (xYZ, viewSubdomain) ->
    VoyageX.TILE_URL_TEMPLATE
      .replace('{z}', xYZ[2])
      .replace('{y}', xYZ[1])
      .replace('{x}', xYZ[0])
      .replace('{s}', viewSubdomain)

  # plugged in via https://github.com/ismyrnow/Leaflet.functionaltilelayer
  # offlineZoom-check is handled in tileUrl()
  @drawTile: (view) ->
    storeKey = Comm.StorageController.tileKey([view.tile.column, view.tile.row, view.zoom])
    console.log 'drawTile - ........................................'+storeKey
    if Comm.StorageController.isFileBased()
      # use File-API
      deferredModeParams = { view: view,\
                             prefetchZoomLevels: true,\
                             save: true,\
                             fileStatusCB: MapControl._fileStatusDeferred,\
                             deferred: $.Deferred(),\
                             promise: null }
      deferredModeParams.promise = deferredModeParams.deferred.promise()
      Comm.StorageController.instance().getTile [view.tile.column, view.tile.row, view.zoom], deferredModeParams
      deferredModeParams.promise
    else
      # use localStorage
      stored = Comm.StorageController.instance().getTile [view.tile.column, view.tile.row, view.zoom]
      unless stored?
        VoyageX.MapControl.tileUrl view
      else
        console.log 'using cached tile: '+storeKey
        stored

  @tileUrl: (view, deferredModeParams = null) ->
    tileUrl = VoyageX.TILE_URL_TEMPLATE
              .replace('{z}', view.zoom)
              .replace('{y}', view.tile.row)
              .replace('{x}', view.tile.column)
              .replace('{s}', view.subdomain)
    if APP.isOnline()
      # if current zoom-level is not offline-zoom-level then load from web
      if view.zoom in MC._offlineZooms
        if deferredModeParams != null
          deferredModeParams.tileUrl = tileUrl
        readyImage = MapControl.loadAndPrefetch [view.tile.column, view.tile.row, view.zoom], view.subdomain, deferredModeParams
      else
        readyImage = tileUrl
        if deferredModeParams != null
          Comm.StorageController.instance().resolveOnlineNotInOfflineZooms tileUrl, deferredModeParams
        MC._prefetchZoomLevels [view.tile.column, view.tile.row, view.zoom], view.subdomain, deferredModeParams
      readyImage
    else
      readyImage = MC._notInCacheImage $('#tile_canvas')[0], view.tile.column, view.tile.row, view.zoom
      if deferredModeParams != null
        Comm.StorageController.instance().resolveOfflineNotInCache readyImage, deferredModeParams
      readyImage

  @_fileStatusDeferred: (deferredModeParams, created) ->
    xYZ = [deferredModeParams.view.tile.column, deferredModeParams.view.tile.row, deferredModeParams.view.zoom]
    console.log 'fileStatusCB (created = '+created+'): xYZ = '+xYZ
    if created
      #if xYZ.toString() == MC._tileLoadQueue[0].xYZ.toString()
      #if MC._saveCallsToFlushCount == MC._tileLoadQueue.length
      tilesToSaveKeys = Object.keys(MC._tileLoadQueue)
      if MC._saveCallsToFlushCount == tilesToSaveKeys.length
        MC._saveCallsToFlushCount = 0
#        #sorted = Object.keys(MC._tileLoadQueue)
#        MC._tileLoadQueue = MC._tileLoadQueue.sort (a, b) ->
#          if a.xYZ[0] > b.xYZ[0]
#            -1
#          else if a.xYZ[0] == b.xYZ[0]
#            if a.xYZ[1] > b.xYZ[1]
#              -1
#            else
#              1
#          else
#            1
        #for idx in [MC._tileLoadQueue-1..0]
        for xY in Object.keys(MC._tileLoadQueue)
        #while (e = MC._tileLoadQueue.pop())?
          #console.log '### _fileStatusDeferred: prefetching area for tileKey = '+e.xYZ
          e = MC._tileLoadQueue[xY]
          #view = {zoom: e.xYZ[2], tile: {column: e.xYZ[0], row: e.xYZ[1]}, subdomain: e.viewSubdomain}
          x = parseInt(MC._map.project(MC._map.getCenter()).x/256)
          y = parseInt(MC._map.project(MC._map.getCenter()).y/256)
          view = {zoom: MC._map.getZoom(), tile: {column: x, row: y}, subdomain: e.viewSubdomain}
          #delete e.deferredModeParams.fileStatusCB
          #
          # instead load heading
          #
          # disable for now: MC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS, e.deferredModeParams
        MC._tileLoadQueue = {}
    else
      #for e, idx in MC._tileLoadQueue
      for xY in Object.keys(MC._tileLoadQueue)
        e = MC._tileLoadQueue[xY]
        if e.xYZ.toString() == xYZ.toString()
          #console.log '### _fileStatusDeferred: removing tileKey = '+e.xYZ
          console.log '### _fileStatusDeferred: removing tileKey = '+e.xYZ
          #MC._tileLoadQueue.splice idx, 1
          delete MC._tileLoadQueue[xY]
          mc._saveCallsToFlushCount -= 1
          break
 
  @loadAndPrefetch: (xYZ, viewSubdomain, deferredModeParams = null) ->
    if Comm.StorageController.isFileBased()
      MC._tileLoadQueue[xYZ[0]+'_'+xYZ[1]] = {xYZ: xYZ, viewSubdomain: viewSubdomain, deferredModeParams: deferredModeParams}
      MC._saveCallsToFlushCount += 1
    readyImage = MC.loadReadyImage MapControl.toUrl(xYZ, viewSubdomain), xYZ, deferredModeParams
    if deferredModeParams == null || deferredModeParams.prefetchZoomLevels
      unless deferredModeParams == null
        deferredModeParams.prefetchZoomLevels = false
      MC._prefetchZoomLevels xYZ, viewSubdomain, deferredModeParams
    readyImage

  @notInCacheImage: (x, y, z) ->
    MC._notInCacheImage $('#tile_canvas')[0], x, y, z

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
                               view: deferredModeParams.view,\
                               xYZ: curXYZ,\
                               tileUrl: MapControl.toUrl(curXYZ, view.subdomain),\
                               prefetchZoomLevels: true,\
                               save: true,\
                               #deferred: deferredModeParams.deferred,\
                               #promise: deferredModeParams.promise }
                               deferred: $.Deferred(),\
                               promise: null }
            prefetchParams.promise = prefetchParams.deferred.promise()
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
              readyImage = MapControl.loadAndPrefetch curXYZ, view.subdomain, deferredModeParams
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
                             view: deferredModeParams.view,\
                             xYZ: curXYZ,\
                             tileUrl: MapControl.toUrl(curXYZ, viewSubdomain),\
                             deferred: $.Deferred(),\
                             promise: null }
          prefetchParams.promise = prefetchParams.deferred.promise()
          Comm.StorageController.instance().prefetchTile prefetchParams
        else
          stored = Comm.StorageController.instance().getTile curXYZ, deferredModeParams
          unless stored?
            parentTileUrl = MapControl.toUrl(curXYZ, viewSubdomain)
            console.log 'prefetching lower-zoom tile: '+parentStoreKey
            readyImage = this.loadReadyImage parentTileUrl, curXYZ, deferredModeParams

  # has to be done sequentially because we're using one canvas for all
  loadReadyImage: (imgUrl, xYZ, deferredModeParams = null) ->
    if deferredModeParams == null
      promise = true
      deferred = $.Deferred()
    img = new Image
    img.crossOrigin = ''
    img.onload = (event) ->
      base64ImgDataUrl = MC._toBase64 $('#tile_canvas')[0], this # event.target
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
    pixelOriginX = parseInt(MC.map().getPixelOrigin().x/256)
    pixelOriginY = parseInt(MC.map().getPixelOrigin().y/256)
    #pixelOriginX = parseInt(MC.map().getPixelBounds().min.x/256)
    #pixelOriginY = parseInt(MC.map().getPixelBounds().min.y/256)
    @_cacheMissTiles.push {top: (y-pixelOriginY)*256, left: (x-pixelOriginX)*256}
    #@_cacheMissTiles.push {top: (pixelOriginY-y)*256+parseInt(MC.map().project(MC.map().getCenter()).x-MC.map().getPixelOrigin().x),\
    #                       left: (pixelOriginX-x)*256+parseInt(MC.map().project(MC.map().getCenter()).y-MC.map().getPixelOrigin().y)}

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
