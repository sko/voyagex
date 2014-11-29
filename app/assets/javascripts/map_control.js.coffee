class window.VoyageX.MapControl

  # later returns data-url: data:image/png;base64,...
  # plugged in via https://github.com/ismyrnow/Leaflet.functionaltilelayer
  @drawTile: (view) ->
    deferred = $.Deferred()
    tileUrl = VoyageX.TILE_URL_TEMPLATE
              .replace('{z}', view.zoom)
              .replace('{y}', view.tile.row)
              .replace('{x}', view.tile.column)
              .replace('{s}', view.subdomain)
    img = new Image
    img.crossOrigin = ''
    img.onload = (event) ->
      base64ImgDataUrl = VoyageX.MapControl._toBase64 $('#tile_canvas')[0], this # event.target
      deferred.resolve(base64ImgDataUrl)
    img.src = tileUrl
    deferred.promise()

  @tileLayer: () ->
    new L.TileLayer.Functional(VoyageX.MapControl.drawTile, {
        subdomains: ['a']
      })

  @_toBase64: (canvas, image) ->
    canvas.width = 256
    canvas.height = 256
    context = canvas.getContext('2d')
    context.drawImage(image, 0, 0)
    canvas.toDataURL('image/png')
