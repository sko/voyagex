class window.VoyageX.StorageStrategy

  @_SINGLETON = new StorageStrategy()

  constructor: () ->
    console.log 'TODO'

  # length/size of stored data: localStorage.tiles.length
  # with webp it's abaout a quarter of the size
  loadTile: (x, y, z) ->
    storeKey = z+'/'+x+'/'+y
    stored = Comm.StorageController.instance().get 'tiles'
    if stored == null || !(geoJSON = stored[storeKey])?
      readyTileUrl = this._loadReadyImage tileUrl
      geoJSON = {
          properties: {
              id: storeKey,
              data: readyTileUrl,
              created_at: Date.now()
            },
          geometry: {
              coordinates: [-1.0, -1.0] # TODO
            }
        }
      Comm.StorageController.instance().addToList 'tiles', storeKey, geoJSON
      readyTileUrl
    else
      console.log 'using cached tile: '+storeKey
      geoJSON.properties.data

  # has to be done sequentially becaus we're using one canvas for all
  _loadImage: (imgUrl) ->
    deferred = $.Deferred()
    img = new Image
    img.crossOrigin = ''
    img.onload = (event) ->
      base64ImgDataUrl = this._toBase64 $('#tile_canvas')[0], this # event.target
      deferred.resolve(base64ImgDataUrl)
    img.src = imgUrl
    deferred.promise()

  _toBase64: (canvas, image) ->
    canvas.width = 256
    canvas.height = 256
    context = canvas.getContext('2d')
    context.drawImage(image, 0, 0)
    canvas.toDataURL('image/webp')

  @instance: () ->
    @_SINGLETON