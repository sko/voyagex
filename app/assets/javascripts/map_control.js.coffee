class window.VoyageX.MapControl

  @_SINGLETON = null

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
    #@_cacheStrategy.getTileUrl tileUrl
    storeKey = view.zoom+'/'+view.tile.column+'/'+view.tile.row
    stored = if view.zoom in VoyageX.MapControl._instance()._offlineZooms then Comm.StorageController.instance().get 'tiles' else null
    if stored == null || !(geoJSON = stored[storeKey])?
      if VoyageX.MapControl._instance()._online
        VoyageX.MapControl._instance()._loadReadyImage tileUrl, storeKey#, deferred
      else
        VoyageX.MapControl._instance()._notInCacheImage $('#tile_canvas')[0], view.tile.column, view.tile.row, view.zoom
    else
      console.log 'using cached tile: '+storeKey
      geoJSON.properties.data

  # has to be done sequentially becaus we're using one canvas for all
  _loadReadyImage: (imgUrl, storeKey) ->
    deferred = $.Deferred()
    img = new Image
    img.crossOrigin = ''
    img.onload = (event) ->
      base64ImgDataUrl = VoyageX.MapControl._instance()._toBase64 $('#tile_canvas')[0], this # event.target
      VoyageX.MapControl._instance()._storeImage(storeKey, base64ImgDataUrl)
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
