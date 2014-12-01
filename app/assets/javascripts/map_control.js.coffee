class window.VoyageX.MapControl

  @_SINGLETON = null

  # zooms msut be sorted from lowest (f.ex. 1) to highest (f.ex. 16)
  constructor: (cacheStrategy, zooms, offlineZooms, online) ->
    @_cacheStrategy = cacheStrategy
    VoyageX.MapControl._SINGLETON = this
    @_online = online
    @_zooms = zooms
    @_minZoom = zooms[0]
    @_maxZoom = zooms[zooms.length - 1]
    @_offlineZooms = offlineZooms

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
  @drawTile: (view) ->
    tileUrl = VoyageX.TILE_URL_TEMPLATE
              .replace('{z}', view.zoom)
              .replace('{y}', view.tile.row)
              .replace('{x}', view.tile.column)
              .replace('{s}', view.subdomain)
    mC = VoyageX.MapControl._instance()
    #@_cacheStrategy.getTileUrl tileUrl
    storeKey = view.zoom+'/'+view.tile.column+'/'+view.tile.row
    stored = if view.zoom in mC._offlineZooms then Comm.StorageController.instance().get 'tiles' else null
    if stored == null || !(geoJSON = stored[storeKey])?
      if mC._online
        console.log 'caching tile: '+storeKey
        readyImage = mC._loadReadyImage tileUrl, storeKey
        # store all tiles in <= zoom-levels
        # 4 small tiles become one bigger tile
        mC._prefetchLowerZoomLevels view
        readyImage
      else
        mC._notInCacheImage $('#tile_canvas')[0], view.tile.column, view.tile.row, view.zoom
    else
      console.log 'using cached tile: '+storeKey
      geoJSON.properties.data

  _prefetchLowerZoomLevels: (view) ->
    curXYZ = [view.tile.column, view.tile.row, view.zoom]
    for n in [(view.zoom-1)..@_minZoom]
      curXYZ = [Math.round((curXYZ[0]-0.1)/2),
                Math.round((curXYZ[1]-0.1)/2),
                n]
      if n in @_offlineZooms
        parentStoreKey = curXYZ[2]+'/'+curXYZ[0]+'/'+curXYZ[1]
        geoJSON = Comm.StorageController.instance().get 'tiles'
        unless geoJSON? && geoJSON[parentStoreKey]?
          #
          # FIXME - doesn't seem to work - stores same key more than once because _loadReadyImage
          # returns soon
          #
          # hack 1: store image here - it's going to be overwritten when image is ready
          this._storeImage(parentStoreKey, null)
          parentTileUrl = VoyageX.TILE_URL_TEMPLATE
                          .replace('{z}', curXYZ[2])
                          .replace('{y}', curXYZ[1])
                          .replace('{x}', curXYZ[0])
                          .replace('{s}', view.subdomain)
          console.log 'prefetching and caching lower-zoom tile: '+parentStoreKey
          this._loadReadyImage parentTileUrl, parentStoreKey

  # has to be done sequentially becaus we're using one canvas for all
  _loadReadyImage: (imgUrl, storeKey) ->
    deferred = $.Deferred()
    img = new Image
    img.crossOrigin = ''
    mC = this
    img.onload = (event) ->
      base64ImgDataUrl = mC._toBase64 $('#tile_canvas')[0], this # event.target
      mC._storeImage(storeKey, base64ImgDataUrl)
      cacheStats({
          tilesSize: Math.round(localStorage.tiles.length/1024)+' kB',
          numTiles: localStorage.tiles.match(/("id":)/g).length
        })
      deferred.resolve(base64ImgDataUrl)
    img.src = imgUrl
    deferred.promise()

  _toBase64: (canvas, image) ->
    canvas.width = 256
    canvas.height = 256
    context = canvas.getContext('2d')
    context.drawImage(image, 0, 0)
    canvas.toDataURL('image/webp')

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
    canvas.toDataURL('image/webp')

  _storeImage: (storeKey, tileDataUrl) ->
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
    Comm.StorageController.instance().addToList 'tiles', storeKey, geoJSON
