#
# tile-length in meters:
# map.containerPointToLatLng(L.point(0,0)).distanceTo(map.containerPointToLatLng(L.point(0,256)))
#
class window.VoyageX.MapControl

  @_SINGLETON = null
#  @_COUNT = 0

  # zooms msut be sorted from lowest (f.ex. 1) to highest (f.ex. 16)
  constructor: (cacheStrategy, mapOptions, offlineZooms, online) ->
    MapControl._SINGLETON = this
    mapOptions.layers = [new L.TileLayer.Functional(VoyageX.MapControl.drawTile, {
        subdomains: mapOptions.subdomains
      })]
    @_mapOptions = mapOptions
    @_cacheStrategy = cacheStrategy
    @_online = online
    @_zooms = mapOptions.zooms
    @_minZoom = @_zooms[0]
    @_maxZoom = @_zooms[@_zooms.length - 1]
    @_offlineZooms = offlineZooms
    @_numTilesCached = 0
    @_tileImageContentType = 'image/webp'
    #@_tileImageContentType = 'image/png'
    @_map = new L.Map('map', mapOptions)
    @_map.whenReady () ->
        console.log 'map is ready ...'
        # TODO: view missing for first load
        #mC = VoyageX.MapControl.instance()
        #readyImage = mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS

  map: () ->
    @_map

  setOnline: () ->
    @_online = true
    @_zooms.splice(0, @_zooms.length)
    for n in [@_minZoom..@_maxZoom]
      @_zooms.push n

  setOffline: () ->
    @_online = false
    @_zooms.splice(0, @_zooms.length)
    for n in @_offlineZooms
      @_zooms.push n

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
    curWidthInMeters = @_map.containerPointToLatLng(L.point(0,0)).distanceTo(@_map.containerPointToLatLng(L.point(0,tileWidth)))
    scaleFactor = @_map.getZoom() - zoomLevel
    curWidthInMeters * Math.pow(2, scaleFactor)

  curTileWidthToMeters: () ->
    this.tileWidthToMeters(@_map.getZoom())

  @instance: () ->
    @_SINGLETON

  @toUrl: (xYZ, viewSubdomain) ->
    VoyageX.TILE_URL_TEMPLATE
      .replace('{z}', xYZ[2])
      .replace('{y}', xYZ[1])
      .replace('{x}', xYZ[0])
      .replace('{s}', viewSubdomain)

  # provides cached tiles
  # static becaus called in context of Leaflet.functionaltilelayer
  # converts tiles to data-url: data:image/png;base64,...
  # and stores them in localStorage
  # plugged in via https://github.com/ismyrnow/Leaflet.functionaltilelayer
  # cat ../tmp/chrome.log | sed "s/.\\+\\?: //" | sort
  @drawTile: (view) ->
#    MapControl._COUNT += 1
#    unless MapControl._COUNT <= 2
#      return VoyageX.TILE_URL_TEMPLATE.replace('{z}', view.zoom).replace('{y}', view.tile.row).replace('{x}', view.tile.column).replace('{s}', view.subdomain)
    mC = VoyageX.MapControl.instance()
    storeKey = Comm.StorageController.storeKey([view.tile.column, view.tile.row, view.zoom])
    if Comm.StorageController.isFileBased()
      console.log 'drawTile - ........................................'+storeKey
      deferredModeParams = { mC: mC,\
                             view: view,\
                             prefetchZoomLevels: true,\
                             save: true,\
                             deferred: $.Deferred(),\
                             promise: null }
      Comm.StorageController.instance().getTile [view.tile.column, view.tile.row, view.zoom], deferredModeParams
      deferredModeParams.promise
    else
      # use localStorage
      stored = if view.zoom in mC._offlineZooms then Comm.StorageController.instance().getTile [view.tile.column, view.tile.row, view.zoom] else null
      #if stored == null || !(geoJSON = stored)?
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
    if mC._online
      # if current zoom-level is not offline-zoom-level then load from web
      if view.zoom in mC._offlineZooms
        if deferredModeParams != null
          deferredModeParams.tileUrl = tileUrl
        # _map maybe not ready on very first call
        if mC._map?
          readyImage = mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS, deferredModeParams
        else
          readyImage = MapControl.loadAndPrefetch mC, [view.tile.column, view.tile.row, view.zoom], view.subdomain, deferredModeParams
      else
        readyImage = tileUrl
        if deferredModeParams != null
          deferredModeParams.tileUrl = readyImage
        mC._prefetchZoomLevels [view.tile.column, view.tile.row, view.zoom], view.subdomain, deferredModeParams
      readyImage
    else
      readyImage = mC._notInCacheImage $('#tile_canvas')[0], view.tile.column, view.tile.row, view.zoom
      if deferredModeParams != null
        Comm.StorageController.instance().resolveOfflineNotInCache readyImage, deferredModeParams
      readyImage

  @loadAndPrefetch: (mC, xYZ, viewSubdomain, deferredModeParams = null) ->
    readyImage = mC._loadReadyImage MapControl.toUrl(xYZ, viewSubdomain), xYZ, deferredModeParams
    if deferredModeParams == null || deferredModeParams.prefetchZoomLevels
      unless deferredModeParams == null
        deferredModeParams.prefetchZoomLevels = false
      mC._prefetchZoomLevels xYZ, viewSubdomain, deferredModeParams
    readyImage

  @notInCacheImage: (x, y, z) ->
    mC = VoyageX.MapControl.instance()
    mC._notInCacheImage $('#tile_canvas')[0], x, y, z

  _prefetchZoomLevels: (xYZ, viewSubdomain, deferredModeParams = null) ->
    storeKey = Comm.StorageController.storeKey([xYZ[0], xYZ[1], xYZ[2]])
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
    centerTile = null
    console.log 'area-prefetch-base: '+Comm.StorageController.storeKey([xYZ[0], xYZ[1], xYZ[2]])
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
        storeKey = Comm.StorageController.storeKey([curXYZ[0], curXYZ[1], curXYZ[2]])
        if Comm.StorageController.isFileBased()
          prefetchParams = { loadTileDataCB: this._loadReadyImage,\
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
          stored = Comm.StorageController.instance().getTile curXYZ, deferredModeParams
         #unless stored? && (deferredModeParams==null || !deferredModeParams.loadAndPrefetch?)
          unless stored?
            console.log 'prefetching area tile: '+storeKey
            readyImage = MapControl.loadAndPrefetch MapControl.instance(), curXYZ, view.subdomain, deferredModeParams
            if addToX == 0 and addToY == 0
              centerTile = readyImage
          else
            #console.log 'area tile already cached: '+storeKey
            if addToX == 0 and addToY == 0
              centerTile = stored
    centerTile

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
        parentStoreKey = curXYZ[2]+'/'+curXYZ[0]+'/'+curXYZ[1]
        if Comm.StorageController.isFileBased()
          prefetchParams = { loadTileDataCB: this._loadReadyImage,\
                             mC: this,\
                             view: deferredModeParams.view,\
                             xYZ: curXYZ,\
                             tileUrl: MapControl.toUrl(curXYZ, viewSubdomain),\
                             deferred: $.Deferred() }
          Comm.StorageController.instance().prefetchTile prefetchParams
        else
          stored = Comm.StorageController.instance().getTile curXYZ, deferredModeParams
          #unless stored? && stored[parentStoreKey]?
          #unless stored? && (!stored.storeFile)
          unless stored?
            parentTileUrl = MapControl.toUrl(curXYZ, viewSubdomain)
            console.log 'prefetching lower-zoom tile: '+parentStoreKey
            readyImage = this._loadReadyImage parentTileUrl, curXYZ, deferredModeParams

  # has to be done sequentially becaus we're using one canvas for all
  _loadReadyImage: (imgUrl, xYZ, deferredModeParams = null) ->
    if deferredModeParams == null
      promise = true
      deferred = $.Deferred()
#    else
#      deferred = deferredModeParams.deferred
    img = new Image
    img.crossOrigin = ''
    mC = this
    img.onload = (event) ->
      base64ImgDataUrl = mC._toBase64 $('#tile_canvas')[0], this # event.target
      unless Comm.StorageController.isFileBased()
        Comm.StorageController.instance().storeImage xYZ, base64ImgDataUrl, deferredModeParams
        cacheStats()
      else
        # actually we could store base64 in file as wall
        #Comm.StorageController.instance().storeImage xYZ, base64ImgDataUrl, deferredModeParams
        $('#tile_canvas')[0].toBlob((blob) ->
            Comm.StorageController.instance().storeImage xYZ, blob, deferredModeParams
          )
      if promise
        deferred.resolve(base64ImgDataUrl)
    img.src = imgUrl
    if promise
      readyImg = deferred.promise()
      # this._loadReadyImage stores Tiles asynchronously so we set empty-tile here to prevent multi-fetch
      Comm.StorageController.instance().storeTile xYZ, null, readyImg, deferredModeParams
      readyImg
    else
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
