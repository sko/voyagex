jQuery ->
  mapEventBroadcast = null

  initPositionCallback = (position) ->
    L.marker([position.coords.latitude, position.coords.longitude]).addTo(map)
    map.panTo([position.coords.latitude, position.coords.longitude])

  $(document).ready () ->
    if navigator.geolocation 
      navigator.geolocation.getCurrentPosition(initPositionCallback);
    mapEventBroadcast = new Faye.Client(document.location.origin+'/comm')
 
  $('#message').on 'keyup', (event) ->
    if (event.which == 13)
      event.preventDefault()
      endIdx = $(this).val().indexOf('\n---')
      if endIdx == -1
        publishText = $(this).val()
      else
        publishText = $(this).val().substr(0, endIdx)
      mapEventBroadcast.publish('/talk', {type: 'message',\
                                          text: $('#client_id').val()+': '+publishText,\
                                          clientId: $('#client_id').val()})
      $(this).val('\n-------------------------\n'+$(this).val())
      $(this).selectRange(0); 
  
  $.fn.selectRange = (start, end) ->
      if !end
        end = start
      this.each () ->
        if this.setSelectionRange
          this.focus()
          this.setSelectionRange(start, end)
        else if this.createTextRange
          range = this.createTextRange()
          range.collapse(true)
          range.moveEnd('character', end)
          range.moveStart('character', start)
          range.select()

  map.on 'click', (event) ->
    L.marker(event.latlng).addTo(map)
    mapEventBroadcast.publish('/map_events', {type: 'click',\
                                              lat: event.latlng.lat,\
                                              lng: event.latlng.lng})
