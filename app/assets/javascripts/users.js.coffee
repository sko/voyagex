if window.VoyageX?
  window.VoyageX.Users = {}
else
  window.VoyageX = { Users: {} }

class window.VoyageX.Users
  
  @_SINGLETON = null

  constructor: () ->
    Users._SINGLETON = this
    window.USERS = this

  initPeer: (peer, callback = null) ->
    #peerPort = peer.peerPort
    #delete peer.peerPort
    lastLocation = peer.lastLocation
    delete peer.lastLocation
    # ---------------------
    poiId = lastLocation.poiId
    if poiId?
      delete lastLocation.poiId
      APP.storage().saveLocation lastLocation, {poi: {id: lastLocation.poiId}}
    else
      unless lastLocation.id?
        # this is just required locally (not in Backend) - to access peers lastLocation later
        lastLocation.id = -peer.id
      APP.storage().saveLocation lastLocation
    # ---------------------
    peer.lastLocationId = lastLocation.id
    USERS.refreshUserPhoto peer, {peerPort: peer.peerPort}, (user, flags) ->
        flags.foto = user.foto
        APP.storage().saveUser user, flags
    if callback?
      callback peer
    if APP.isOnline() && APP._comm.isReady()
      USERS.subscribeToPeerChannels peer
    else
      BANG
      subscribeTo.push peer
    #APP.storage().saveUser {id: #{cs.user.id}, username: '#{cs.user.username}', peerPort: {id: #{cs.id}, channel_enc_key: '#{cs.channel_enc_key'}});
    APP.view().addIFollow peer
    marker = APP.getPeerMarker peer, lastLocation

  initUser: (user) ->
    flags = user.flags||{}
    delete user.flags
    if flags.i_follow?
      USERS.initPeer user
    else
      if flags.i_want_to_follow?
        USERS.refreshUserPhoto user, {peerPort: {}}, (u, flags) ->
            APP.storage().saveUser u, {foto: u.foto}
            APP.view().addIWantToFollow u
      APP.view().addIDontFollow user
    if flags.follows_me?
      USERS.refreshUserPhoto user, {peerPort: {}}, (u, flags) ->
          APP.storage().saveUser u, {foto: u.foto}
          APP.view().addFollowsMe u
    else if flags.wants_to_follow_me?
      APP.view().addWantsToFollowMe user
    # if window.isMobile()
    #   # required for applying layout
    #   $('#comm_peer_data').trigger("create")

  initUsers: (users) ->
    #APP.view().clearFollows()
    for user in users
      USERS.initUser user
    # if window.isMobile()
    #   # required for applying layout
    #   $('#comm_peer_data').trigger("create")

  # saveCB recommended for currentUser
  # USERS.refreshUserPhoto newU, null, (user, flags) ->
  #     APP.storage().saveCurrentUser user
  refreshUserPhoto: (user, flags = null, saveCB = null) ->
    unless flags?
      flags = { foto: user.foto }
    userPhotoUrl = Storage.Model.storedUserPhoto user
    if (typeof userPhotoUrl == 'string') 
      user.foto.url = userPhotoUrl
      if flags?
        if flags.foto? then (flags.foto.url = userPhotoUrl) else (flags.foto = {url: userPhotoUrl})
      else
        flags = {foto: {url: userPhotoUrl}}
      if saveCB?
        saveCB user, flags
      else
        APP.storage().saveUser { id: user.id, username: user.username }, flags
      if flags.peerPort?
        $('img[name=peer_photo_'+user.id+']').attr 'src', userPhotoUrl
      else
        $('.whoami-img').attr('src', userPhotoUrl)
    else if (typeof userPhotoUrl.then == 'function')
      # Assume we are dealing with a promise.
      if flags.peerPort?
        $('img[name=peer_photo_'+user.id+']').attr 'src', VoyageX.IMAGES_SWIPER_LOADING_PATH
      else
        $('.whoami-img').attr 'src', VoyageX.IMAGES_SWIPER_LOADING_PATH
      userPhotoUrl.then (url) ->
          user.foto.url = url
          if flags?
            if flags.foto? then (flags.foto.url = url) else (flags.foto = {url: url})
          else
            flags = {foto: {url: url}}
          if saveCB?
            saveCB user, flags
          else
            APP.storage().saveUser { id: user.id, username: user.username }, flags
          if flags.peerPort?
            $('img[name=peer_photo_'+user.id+']').attr 'src', url
          else
            $('.whoami-img').attr 'src', url

  resetConnection: (peerId) ->
    peerChannelEncKey = $('#i_follow_'+peerId).attr('data-channelEncKey')
    USERS.unsubscribeFromPeerChannels {peerPort: {channel_enc_key: peerChannelEncKey}}
    USERS.subscribeToPeerChannels {peerPort: {channel_enc_key: peerChannelEncKey}}

  subscribeToAllPeerChannels: () ->
    if APP.isOnline() && APP._comm.isReady()
      while (peer = subscribeTo.pop())
        USERS.subscribeToPeerChannels peer

  subscribeToPeerChannels: (peer) ->
    for channel in VoyageX.Main.commChannels()
      if channel == 'system'
        continue
      channelPath = '/'+channel
      unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
        channelPath += VoyageX.PEER_CHANNEL_PREFIX+peer.peerPort.channel_enc_key
      Comm.Comm.subscribeTo channelPath, Comm.Comm.channelCallBacksJSON[channel].callback

  #unsubscribePeerChannel: (peer) ->

  unsubscribeFromPeerChannels: (peer) ->
    for channel in VoyageX.Main.commChannels()
      if channel == 'system'
        continue
      channelPath = '/'+channel
      unless window.VoyageX.USE_GLOBAL_SUBSCRIBE 
        channelPath += VoyageX.PEER_CHANNEL_PREFIX+peer.peerPort.channel_enc_key
      Comm.Comm.unsubscribeFrom channelPath
