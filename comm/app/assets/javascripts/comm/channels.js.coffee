talkClient = new Faye.Client(document.location.origin+'/comm')
subscription = talkClient.subscribe '/talk', (message) ->
  console.log 'got a talk - message: ' + message
  if $('#client_id').val() != message.clientId
    $('#message').val('\n-------------------------\n'+message.text+$('#message').val())
    $('#message').selectRange(0); 
subscription = talkClient.subscribe '/map_events', (mapEvent) ->
  console.log 'got a map_events - message: ' + mapEvent.type
  map.panTo([mapEvent.lat, mapEvent.lng])
  L.marker([mapEvent.lat, mapEvent.lng]).addTo(map)
