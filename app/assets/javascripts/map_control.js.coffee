#
# tile-length in meters:
# map.containerPointToLatLng(L.point(0,0)).distanceTo(map.containerPointToLatLng(L.point(0,256)))
#
class window.VoyageX.MapControl

  @_SINGLETON = null
  @_FS = null

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
    @_fs = null
#    @_grantedBytes = 0
#    requestedBytes = Math.pow(2, 24) # 16MB
#    navigator.webkitPersistentStorage.requestQuota(requestedBytes, (grantedBytes) ->
#        window.webkitRequestFileSystem(PERSISTENT, grantedBytes, VoyageX.MapControl.onInitFs, VoyageX.MapControl.onFsError)
#      , (e) ->
#        console.log('Error', e)
#      )
    @_map = new L.Map('map', mapOptions)
    @_map.whenReady () ->
        console.log 'map is ready ...'
        # TODO: view missing for first load
        #mC = VoyageX.MapControl._instance()
        #readyImage = mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS


  @onInitFs: (fs) ->
    console.log('filesystem zugang')
    VoyageX.MapControl._FS = fs

  @onFsError: (e) ->
    console.log('kein filesystem zugang')

  @onFileError: (e) ->
    console.log('kein file zugang')

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

  @_instance: () ->
    @_SINGLETON

  # provides cached tiles
  # static becaus called in context of Leaflet.functionaltilelayer
  # converts tiles to data-url: data:image/png;base64,...
  # and stores them in localStorage
  # plugged in via https://github.com/ismyrnow/Leaflet.functionaltilelayer
  # cat ../tmp/chrome.log | sed "s/.\\+\\?: //" | sort
  @drawTile: (view) ->
    tileUrl = VoyageX.TILE_URL_TEMPLATE
              .replace('{z}', view.zoom)
              .replace('{y}', view.tile.row)
              .replace('{x}', view.tile.column)
              .replace('{s}', view.subdomain)
    mC = VoyageX.MapControl._instance()
    storeKey = VoyageX.MapControl.storeKey([view.tile.column, view.tile.row, view.zoom])
    stored = if view.zoom in mC._offlineZooms then Comm.StorageController.instance().getTile [view.tile.column, view.tile.row, view.zoom] else null
    if stored == null || !(geoJSON = stored[storeKey])?
      if mC._online
        # if current zoom-level is not offline-zoom-level then load from web
        if view.zoom in mC._offlineZooms
          if mC._map?
            readyImage = mC._prefetchArea view, VoyageX.SEARCH_RADIUS_METERS
          else
            #readyImage = mC._loadReadyImage tileUrl, [view.tile.column, view.tile.row, view.zoom]
            readyImage = mC._loadAndPrefetch [view.tile.column, view.tile.row, view.zoom], view.subdomain
        else
          readyImage = tileUrl
          mC._prefetchZoomLevels [view.tile.column, view.tile.row, view.zoom], view.subdomain
#        # store 1 higher zoomlevel if current zoomlevel is not in @_offlineZooms
#        for z in mC._offlineZooms
#          if z > view.zoom
#            console.log 'prefetch-base: '+storeKey
#            mC._prefetchHigherZoomLevel [view.tile.column, view.tile.row, view.zoom], (z-view.zoom-1)
#            break
#        # store all tiles in <= zoom-levels
#        # 4 small tiles become one bigger tile
#        mC._prefetchLowerZoomLevels [view.tile.column, view.tile.row, view.zoom], view.subdomain
        readyImage
      else
        mC._notInCacheImage $('#tile_canvas')[0], view.tile.column, view.tile.row, view.zoom
    else
      console.log 'using cached tile: '+storeKey
      geoJSON.properties.data

  @storeKey: (xYZ) ->
    xYZ[2]+'/'+xYZ[0]+'/'+xYZ[1]

  _loadAndPrefetch: (xYZ, viewSubdomain) ->
    tileUrl = VoyageX.TILE_URL_TEMPLATE
              .replace('{z}', xYZ[2])
              .replace('{y}', xYZ[1])
              .replace('{x}', xYZ[0])
              .replace('{s}', viewSubdomain)
    readyImage = this._loadReadyImage tileUrl, xYZ
    this._prefetchZoomLevels xYZ, viewSubdomain
    readyImage

  _prefetchZoomLevels: (xYZ, viewSubdomain) ->
    storeKey = VoyageX.MapControl.storeKey([xYZ[0], xYZ[1], xYZ[2]])
    # store 1 higher zoomlevel if current zoomlevel is not in @_offlineZooms
    for z in @_offlineZooms
      if z > xYZ[2]
        console.log 'prefetch-base: '+storeKey
        this._prefetchHigherZoomLevel xYZ, (z-xYZ[2]-1)
        break
    # store all tiles in <= zoom-levels
    # 4 small tiles become one bigger tile
    this._prefetchLowerZoomLevels xYZ, viewSubdomain

  _prefetchArea: (view, radiusMeters) ->
    xYZ = [view.tile.column, view.tile.row, view.zoom]
    storeKey = VoyageX.MapControl.storeKey([xYZ[0], xYZ[1], xYZ[2]])
    centerTile = null
    console.log 'area-prefetch-base: '+storeKey
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
        # TODO for each tile zoom in and out
        storeKey = VoyageX.MapControl.storeKey([curXYZ[0], curXYZ[1], curXYZ[2]])
        geoJSON = Comm.StorageController.instance().getTile curXYZ
        unless geoJSON? && geoJSON[storeKey]?
          console.log 'prefetching area tile: '+storeKey
          #tileUrl = VoyageX.TILE_URL_TEMPLATE
          #          .replace('{z}', curXYZ[2])
          #          .replace('{y}', curXYZ[1])
          #          .replace('{x}', curXYZ[0])
          #          .replace('{s}', view.subdomain)
          #readyImage = this._loadReadyImage tileUrl, curXYZ
          readyImage = this._loadAndPrefetch curXYZ, view.subdomain
          if addToX == 0 and addToY == 0
            centerTile = readyImage
        else
          console.log 'area tile already cached: '+storeKey
          if addToX == 0 and addToY == 0
            centerTile = geoJSON[storeKey].properties.data
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

  _prefetchLowerZoomLevels: (curXYZ, viewSubdomain) ->
    for n in [(curXYZ[2]-1)..@_minZoom]
      curXYZ = [Math.round((curXYZ[0]-0.1)/2),
                Math.round((curXYZ[1]-0.1)/2),
                n]
      if n in @_offlineZooms
        parentStoreKey = curXYZ[2]+'/'+curXYZ[0]+'/'+curXYZ[1]
        geoJSON = Comm.StorageController.instance().getTile curXYZ
        unless geoJSON? && geoJSON[parentStoreKey]?
          parentTileUrl = VoyageX.TILE_URL_TEMPLATE
                          .replace('{z}', curXYZ[2])
                          .replace('{y}', curXYZ[1])
                          .replace('{x}', curXYZ[0])
                          .replace('{s}', viewSubdomain)
          console.log 'prefetching lower-zoom tile: '+parentStoreKey
          readyImage = this._loadReadyImage parentTileUrl, curXYZ

  # has to be done sequentially becaus we're using one canvas for all
  _loadReadyImage: (imgUrl, xYZ) ->
    deferred = $.Deferred()
    img = new Image
    img.crossOrigin = ''
    mC = this
    img.onload = (event) ->
      base64ImgDataUrl = mC._toBase64 $('#tile_canvas')[0], this # event.target
      mC._storeImage(xYZ, base64ImgDataUrl)
      deferred.resolve(base64ImgDataUrl)
    img.src = imgUrl
    readyImg = deferred.promise()
    # this._loadReadyImage stores Tiles asynchronously so we set empty-tile here to prevent multi-fetch
    Comm.StorageController.instance().storeTile xYZ, null, readyImg
    readyImg

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

  _storeImage: (xYZ, tileDataUrl) ->
#    if VoyageX.MapControl._FS?
#      fileEntry = this._getFileEntry xYZ
    storeKey = VoyageX.MapControl.storeKey xYZ
    geoJSON = {
        properties: {
            id: storeKey,
            data: tileDataUrl,
            created_at: Date.now()
          },
        geometry: {
            coordinates: [-1.0, -1.0] # TODO
          }
      }
    #Comm.StorageController.instance().addToList 'tiles', storeKey, geoJSON
    Comm.StorageController.instance().storeTile xYZ, geoJSON
    @_numTilesCached += 1
    console.log 'cached tile(#'+@_numTilesCached+'): '+storeKey
    cacheStats()

  _getFileEntry: (xYZ) ->
    deferred = $.Deferred()
    VoyageX.MapControl._FS.root.getFile(xYZ[2], {}, (fileEntry) ->
        console.log('fileEntry = '+fileEntry.fullPath)
        #alert(fileEntry.fullPath)
        deferred.resolveWith(fileEntry)
      , VoyageX.MapControl.onFileError)
    deferred.promise()
