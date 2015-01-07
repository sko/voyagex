class window.VoyageX.MediaManager

  @_SINGLETON = null

  constructor: () ->
    MediaManager._SINGLETON = this
    @_audioSourceIds = null
    @_curSelAudSrcIdx = -1
    @_videoSourceIds = null
    @_curSelVidSrcIdx = -1
    # coffedscript would compile MediaStreamTrack.getSources? to "MediaStreamTrack.getSources != null" only
    if MediaStreamTrack? && (`MediaStreamTrack.getSources !== undefined`)
      initMediaSources(this)
    @_audioPlayer = null
    try
      AudioContext = window.AudioContext||window.webkitAudioContext;
      @_audioPlayer = new AudioContext()
    catch error
      console.log('no audio-player-support', error)

  initMediaSources = (mm) ->
    MediaStreamTrack.getSources((sourceInfos) ->
      mm._audioSourceIds = []
      mm._videoSourceIds = []
      for sourceInfo in sourceInfos
        if (sourceInfo.kind == 'audio') 
          console.log(sourceInfo.id, sourceInfo.label || 'microphone')
          mm._audioSourceIds.push sourceInfo.id
          mm._curSelAudSrcIdx = 0
        else if (sourceInfo.kind == 'video') 
          console.log(sourceInfo.id, sourceInfo.label || 'camera')
          mm._videoSourceIds.push sourceInfo.id
          mm._curSelVidSrcIdx = 0
        else
          console.log('Some other kind of source: ', sourceInfo)
      )
  
  curSelectedAudioSrcIdx: () ->
    @_curSelAudSrcIdx
  
  curSelectedVideoSrcIdx: () ->
    @_curSelVidSrcIdx
  
  nextSelectedVideoSrcIdx: () ->
    if @_curSelVidSrcIdx == -1
      return -1
    if @_curSelVidSrcIdx >= @_videoSourceIds.length - 1
      0
    else
      @_curSelVidSrcIdx + 1

  constraintsForMediaSource: (audioSourceIdx, videoSourceIdx) ->
    constraints = {}
    if audioSourceIdx >= 0
      constraints.audio = {\
            optional: [{sourceId: @_audioSourceIds[audioSourceIdx]}]\
          }
      @_curSelAudSrcIdx = audioSourceIdx
    if videoSourceIdx >= 0
      constraints.video = {\
            optional: [{sourceId: @_videoSourceIds[videoSourceIdx]}]\
          }
      @_curSelVidSrcIdx = videoSourceIdx
    return constraints

  drawRotated: (degrees, canvas, image) ->
    context = canvas.getContext('2d')
    context.clearRect(0, 0, canvas.width, canvas.height);
    # save the unrotated context of the canvas so we can restore it later
    # the alternative is to untranslate & unrotate after drawing
    context.save();
    # move to the center of the canvas
    context.translate(canvas.width/2, canvas.height/2);
    # rotate the canvas to the specified degrees
    context.rotate(degrees*Math.PI/180);
    # draw the image
    # since the context is rotated, the image will be rotated also
    context.drawImage(image, -image.width/2, -image.width/2);
    # we’re done with the rotating so restore the unrotated context
    context.restore();

  playSound: (filePath, callback = null) ->
    if @_audioPlayer?
      audio1 = MediaManager.instance()._audioPlayer.createBufferSource()
      stopCB = () ->
        audio1.stop()
        #audio1.currentTime = 0
      bufferLoader = new BufferLoader(
        @_audioPlayer,
        [
          filePath
        ],
        (bufferList) ->
            audio1.buffer = bufferList[0]
            audio1.connect(MediaManager.instance()._audioPlayer.destination)
            if callback?
              audio1.onended = () ->
                  callback {msg: 'finished'}
            audio1.start(0)
      )
      bufferLoader.load()
      stopCB

  @instance: () ->
    @_SINGLETON
