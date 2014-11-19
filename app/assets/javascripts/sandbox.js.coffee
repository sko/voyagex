jQuery ->
  comm = null
  window.commListeners = {
                           talk: [],
                           mapEvents: [],
                           uploads: []
                         }

  selectedPositionLatLng = [-1, -1]

  window.getSelectedPositionLatLng = () ->
    return [selectedPositionLatLng[0], selectedPositionLatLng[1]]

  setSelectedPositionLatLng = (lat, lng) ->
    selectedPositionLatLng[0] = lat
    selectedPositionLatLng[1] = lng

  initPositionCB = (position) ->
    setSelectedPositionLatLng(position.coords.latitude, position.coords.longitude)
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
    setSelectedPositionLatLng(mapEvent.lat, mapEvent.lng)
    map.panTo([mapEvent.lat, mapEvent.lng])
    L.marker([mapEvent.lat, mapEvent.lng]).addTo(map)
    for listener in window.commListeners.mapEvents
      listener(mapEvent)

  uploadsCB = (upload) ->
    console.log 'got an uploads - message: ' + upload.type
    $("#upload_preview").prepend(upload.htmlTag);
    for listener in window.commListeners.uploads
      listener(upload)

  markerEventsCB = (position) ->
    setSelectedPositionLatLng(position.coords.latitude, position.coords.longitude)
    L.marker([position.coords.latitude, position.coords.longitude]).addTo(map)
    map.panTo([position.coords.latitude, position.coords.longitude])

  $(document).ready () ->
    if navigator.geolocation 
      navigator.geolocation.getCurrentPosition(initPositionCB, (error) ->
          alert('geolocation timed out - manual selection required')
      , { enableHighAccuracy: true, timeout : 10000 })
    comm = new Comm([['/talk', talkCB],
                     ['/map_events', mapEventsCB],
                     ['/uploads', uploadsCB]])
 
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
    marker = L.marker(event.latlng)
    marker.on 'click', markerEventsCB
    marker.addTo(map)
    comm.send('/map_events', {type: 'click',\
                              userId: $('#current_user_id').val(),\
                              lat: event.latlng.lat,\
                              lng: event.latlng.lng})
