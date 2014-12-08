#
# tile-length in meters:
# map.containerPointToLatLng(L.point(0,0)).distanceTo(map.containerPointToLatLng(L.point(0,256)))
#
class window.VoyageX.MapControl

  @_SINGLETON = null
  @_FS = null

  # zooms msut be sorted from lowest (f.ex. 1) to highest (f.ex. 16)
  constructor: (cacheStrategy, zooms, offlineZooms, online) ->
    MapControl._SINGLETON = this
    @_cacheStrategy = cacheStrategy
    @_online = online
    @_zooms = zooms
    @_minZoom = zooms[0]
    @_maxZoom = zooms[zooms.length - 1]
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

  @onInitFs: (fs) ->
    console.log('filesystem zugang')
    VoyageX.MapControl._FS = fs

  @onFsError: (e) ->
    console.log('kein filesystem zugang')

  @onFileError: (e) ->
    console.log('kein file zugang')

  tileLayer: () ->
    new L.TileLayer.Functional(VoyageX.MapControl.drawTile, {
        subdomains: ['a']
      })

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
   #stored = if view.zoom in mC._offlineZooms then Comm.StorageController.instance().get 'tiles' else null
    stored = if view.zoom in mC._offlineZooms then Comm.StorageController.instance().getTile [view.tile.column, view.tile.row, view.zoom] else null
    if stored == null || !(geoJSON = stored[storeKey])?
      if mC._online
        # if current zoom-level is not offline-zoom-level then load from web
        if view.zoom in mC._offlineZooms
          readyImage = mC._loadReadyImage tileUrl, [view.tile.column, view.tile.row, view.zoom]
        else
          readyImage = tileUrl
        # store 1 higher zoomlevel if current zoomlevel is not in @_offlineZooms
        for z in mC._offlineZooms
          if z > view.zoom
            console.log 'prefetch-base: '+storeKey
            mC._prefetchHigherZoomLevel [view.tile.column, view.tile.row, view.zoom], (z-view.zoom-1)
            break
        # store all tiles in <= zoom-levels
        # 4 small tiles become one bigger tile
        mC._prefetchLowerZoomLevels view
        readyImage
      else
        mC._notInCacheImage $('#tile_canvas')[0], view.tile.column, view.tile.row, view.zoom
    else
      console.log 'using cached tile: '+storeKey
      geoJSON.properties.data

  @storeKey: (xYZ) ->
    xYZ[2]+'/'+xYZ[0]+'/'+xYZ[1]

  # fetch all tiles for next higher zoom-level.
  # 1 level difference -> 4 tiles, 2 level -> 16, ...
  # left: startingZoomLevel - nextHigherOfflineZoomLevel
  # levelDiffLimit: max num of higher zoom-levels to check
  # depth: internal recursion counter
  _prefetchHigherZoomLevel: (XYZ, left, levelDiffLimit = 1, depth = 1) ->
    for addToX in [0,1]
      for addToY in [0,1]
        curXYZ = [XYZ[0]*2+addToX,
                  XYZ[1]*2+addToY,
                  XYZ[2]+1]
        if left >= 1 && depth < levelDiffLimit
          this._prefetchHigherZoomLevel curXYZ, (left-1), levelDiffLimit, (depth+1)
        if curXYZ[2] in @_offlineZooms
          curStoreKey = curXYZ[2]+'/'+curXYZ[0]+'/'+curXYZ[1]
          console.log 'TODO: prefetch higher zoom tile: '+curStoreKey

  _prefetchLowerZoomLevels: (view) ->
    curXYZ = [view.tile.column, view.tile.row, view.zoom]
    for n in [(view.zoom-1)..@_minZoom]
      curXYZ = [Math.round((curXYZ[0]-0.1)/2),
                Math.round((curXYZ[1]-0.1)/2),
                n]
      if n in @_offlineZooms
        parentStoreKey = curXYZ[2]+'/'+curXYZ[0]+'/'+curXYZ[1]
        geoJSON = Comm.StorageController.instance().getTile curXYZ
        unless geoJSON? && geoJSON[parentStoreKey]?
          # this._loadReadyImage stores Tiles asynchronously so we set empty-tile here to prevent multi-fetch
          Comm.StorageController.instance().storeTile curXYZ, null
          parentTileUrl = VoyageX.TILE_URL_TEMPLATE
                          .replace('{z}', curXYZ[2])
                          .replace('{y}', curXYZ[1])
                          .replace('{x}', curXYZ[0])
                          .replace('{s}', view.subdomain)
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
    deferred.promise()

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
