jQuery ->
  comm = null
  window.commListeners = {
                           talk: [],
                           mapEvents: []
                         }

  initPositionCB = (position) ->
    L.marker([position.coords.latitude, position.coords.longitude]).addTo(map)
    map.panTo([position.coords.latitude, position.coords.longitude])

  talkCB = (message) ->
    console.log 'got a talk - message: ' + message
    if $('#current_user_id').val() != message.userId
      $('#message').val('\n-------------------------\n'+message.text+$('#message').val())
      $('#message').selectRange(0); 
      for listener in window.commListeners.talk
        listener(message)

  mapEventsCB = (mapEvent) ->
    console.log 'got a map_events - message: ' + mapEvent.type
    map.panTo([mapEvent.lat, mapEvent.lng])
    L.marker([mapEvent.lat, mapEvent.lng]).addTo(map)
    for listener in window.commListeners.mapEvents
      listener(mapEvent)

  $(document).ready () ->
    if navigator.geolocation 
      navigator.geolocation.getCurrentPosition(initPositionCB);
    comm = new Comm([['/talk', talkCB],
                     ['/map_events', mapEventsCB]])
 
  $('#message').on 'keyup', (event) ->
    if (event.which == 13 || event.keyCode == 13)
      event.preventDefault()
      endIdx = $(this).val().indexOf('\n---')
      if endIdx == -1
        publishText = $(this).val()
      else
        publishText = $(this).val().substr(0, endIdx)
      comm.send('/talk', {type: 'message',\
                          text: $('#current_user_id').val()+': '+publishText,\
                          userId: $('#current_user_id').val()})
      $(this).val('\n-------------------------\n'+$(this).val())
      $(this).selectRange(0); 
  
  map.on 'click', (event) ->
    L.marker(event.latlng).addTo(map)
    comm.send('/map_events', {type: 'click',\
                              userId: $('#current_user_id').val(),\
                              lat: event.latlng.lat,\
                              lng: event.latlng.lng})
