class window.VoyageX.MediaManager

  constructor: () ->
    @_audioSourceIds = null
    @_curSelAudSrcIdx = -1
    @_videoSourceIds = null
    @_curSelVidSrcIdx = -1
    unless typeof MediaStreamTrack == 'undefined'
      initMediaSources(this)

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
