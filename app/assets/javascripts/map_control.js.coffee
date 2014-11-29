class window.VoyageX.MapControl

  # provides cached tiles
  # converts tiles to data-url: data:image/png;base64,...
  # and stores them in localStorage
  # plugged in via https://github.com/ismyrnow/Leaflet.functionaltilelayer
  @drawTile: (view) ->
    deferred = $.Deferred()
    tileUrl = VoyageX.TILE_URL_TEMPLATE
              .replace('{z}', view.zoom)
              .replace('{y}', view.tile.row)
              .replace('{x}', view.tile.column)
              .replace('{s}', view.subdomain)
    storeKey = view.zoom+'/'+view.tile.column+'/'+view.tile.row
    stored = Comm.StorageController.instance().get 'tiles'
    if stored == null || !(geoJSON = stored[storeKey])?
      img = new Image
      img.crossOrigin = ''
      img.onload = (event) ->
        #base64ImgDataUrl = VoyageX.MapControl._toBase64 $('#tile_canvas')[0], this # event.target
        # length/size of stored data: localStorage.tiles.length
        # with webp it's abaout a quarter of the size
        storeKey = view.zoom+'/'+view.tile.column+'/'+view.tile.row
        base64ImgDataUrl = VoyageX.MapControl._toBase64 $('#tile_canvas')[0], this # event.target
        # type: Feature, geometry.type: Polygon are transparent
        geoJSON = {
            properties: {
                id: storeKey,
                data: base64ImgDataUrl,
                created_at: Date.now()
              },
            geometry: {
                coordinates: [-1.0, -1.0] # TODO
              }
          }
        Comm.StorageController.instance().addToList 'tiles', storeKey, geoJSON
        deferred.resolve(base64ImgDataUrl)
      img.src = tileUrl
      deferred.promise()
    else
      console.log 'using cached tile: '+storeKey
      geoJSON.properties.data

  @tileLayer: () ->
    new L.TileLayer.Functional(VoyageX.MapControl.drawTile, {
        subdomains: ['a']
      })

  @_toBase64: (canvas, image) ->
    canvas.width = 256
    canvas.height = 256
    context = canvas.getContext('2d')
    context.drawImage(image, 0, 0)
    canvas.toDataURL('image/webp')
