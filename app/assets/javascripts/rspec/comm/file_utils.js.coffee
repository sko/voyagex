class window.Comm.FileUtils
  
  @_FS = null

  constructor: (requestedBytes, storedFilesAreBase64, fsInitCB) ->
    @_grantedBytes = 0
    @_dirReaders = {}
    try
      fileAPISupport = `navigator.webkitPersistentStorage !== undefined`
    catch error
      fileAPISupport = false
    console.log('FileUtils.constructor - fileAPISupport = '+fileAPISupport)
    if fileAPISupport
      window.webkitStorageInfo.queryUsageAndQuota(webkitStorageInfo.PERSISTENT, 
          (used, remaining) ->
              console.log("Used quota: " + used + ", remaining quota: " + remaining)
          , (e) ->
              console.log('Error', e)
          )
      # @deprecated
      #window.webkitStorageInfo.queryUsageAndQuota(webkitStorageInfo.PERSISTENT,  (used, remaining) ->
      #window.webkitStorageInfo.requestQuota(webkitStorageInfo.PERSISTENT, requestedBytes, (grantedBytes) ->
      navigator.webkitPersistentStorage.requestQuota(requestedBytes, (grantedBytes) ->
          #window.webkitRequestFileSystem(PERSISTENT, grantedBytes, FileUtils.onInitFs, FileUtils.onFsError)
          # @deprecated
          window.webkitRequestFileSystem(webkitStorageInfo.PERSISTENT, grantedBytes, (fs) ->
                console.log('filesystem zugang')
                sC = FileUtils.instance()
                sC._dirReaders = { parent: null, path: '/', entry: fs.root, reader: fs.root.createReader(), entries: {} }
                FileUtils._FS = fs
                fsInitCB false
            ,
            (e) ->
                console.log('kein filesystem zugang')
                fsInitCB true
            )
        , (e) ->
            console.log('Error', e); 
            fsInitCB true
        )
    else
      fsInitCB true

  # directory path for storing with file-api
  @poiNoteAttachmentPath: (poiNote) ->
    ['poiNotes', 'attachments', ''+poiNote.id]

  _removeDirectory: (dirName) ->
    @_dirReaders.entry.getDirectory(dirName, {}, (dirEntry) ->
            dirEntry.removeRecursively(() ->
                console.log('removing directory '+dirName+' ...')
              , (e) ->
                console.log('error when removing directory '+dirName+': ', e)
              )
          , (e) ->
              console.log('error when removing directory '+dirName+': ', e)
          )

  _saveFile: (xYZ, fileIdx, dirReader, data, deferredModeParams) ->
    sC = FileUtils.instance()
    path = dirReader.path+'/'+xYZ[fileIdx]
    dirReader.entry.getFile(xYZ[fileIdx], {}, (fileEntry) ->
        #unless dirReader.entries[xYZ[fileIdx]]?
        #  dirReader.entries[xYZ[fileIdx]] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
        # TODO - what is this for? is this call necessary?
        sC._storeTileAsFile xYZ, dirReader, null, deferredModeParams
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          dirReader.entry.getFile(xYZ[fileIdx], {create: true}, (fileEntry) ->
                fileEntry.createWriter((fileWriter) ->
                  fileWriter.onwriteend = (e) ->
                      console.log('Write completed.')
                      if deferredModeParams.fileStatusCB?
                        deferredModeParams.fileStatusCB deferredModeParams, true
                      deferredModeParams.deferred.resolve fileEntry.toURL(FileUtils.instance()._tileImageContentType)
                      storeKey = FileUtils.tileKey(xYZ)
                      delete sC._tileLoadQueue[storeKey]
                      tileMeta = localStorage.getItem 'comm.tiles.tileMeta'
                      if tileMeta == null
                        sC._tileMeta = { tilesByteSize: 0, numTiles: 0 }
                      else
                        sC._tileMeta = eval("(" + tileMeta + ")")
                      #sC._tileDB[storeKey] = data.properties.data
                      sC._tileMeta.numTiles = sC._tileMeta.numTiles+1
                      sC._tileMeta.tilesByteSize = sC._tileMeta.tilesByteSize+data.properties.data.size
                      localStorage.setItem 'comm.tiles.tileMeta', JSON.stringify(sC._tileMeta)
                      showCacheStats(sC._tileMeta.numTiles, sC._tileMeta.tilesByteSize)
                  fileWriter.onerror = (e) ->
                      console.log('Write failed: ' + e.toString())
                      if deferredModeParams.fileStatusCB?
                        deferredModeParams.fileStatusCB deferredModeParams, true
                      #deferredModeParams.deferred.resolve deferredModeParams.tileUrl
                      deferredModeParams.deferred.resolve VoyageX.MapControl.notInCacheImage(xYZ[0], xYZ[1], xYZ[2])
                      delete sC._tileLoadQueue[FileUtils.tileKey(xYZ)]
                  console.log('saving file: '+path)
                  fileWriter.write(new Blob([data.properties.data], {type: sC._tileImageContentType}))
                  # text-files
                  #fileWriter.write(data.properties.data)
                , (e) ->
                    console.log('_saveFile - '+e+' when trying to WRITE file '+path)
                )
            , (e) ->
                console.log('_saveFile - '+e+' when trying to SAVE file '+path)
            )
        else
          console.log('_saveFile - '+e+' when trying to STORE file '+path)
          sC._storeTileAsFile xYZ, dirReader, null, deferredModeParams
      )

  # '/'+xYZ[2]+'/'+xYZ[0]+'/'+xYZ[1]
  _getDirectory: (xYZ, nextDirIdx, dirReader, data, deferredModeParams, firstCall = true) ->
    sC = FileUtils.instance()
    path = (if dirReader.parent == null then '' else dirReader.path)+'/'+xYZ[nextDirIdx]
    dirReader.entry.getDirectory(xYZ[nextDirIdx], {}, (fileEntry) ->
        #console.log('found directory: '+path)
        unless dirReader.entries[xYZ[nextDirIdx]]?
          dirReader.entries[xYZ[nextDirIdx]] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
        sC._storeTileAsFile xYZ, dirReader.entries[xYZ[nextDirIdx]], data, deferredModeParams
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          console.log('creating tile-directory: '+path)
          dirReader.entry.getDirectory(xYZ[nextDirIdx], {create: true, exclusive: true}, (fileEntry) ->
              unless dirReader.entries[xYZ[nextDirIdx]]?
                dirReader.entries[xYZ[nextDirIdx]] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
              sC._storeTileAsFile xYZ, dirReader.entries[xYZ[nextDirIdx]], data, deferredModeParams
            , (e) ->
              if (e.code == FileError.NOT_FOUND_ERR) 
                console.log('_getDirectory - No such file: '+path)
              else
                # it's likely that directory has been created meanwhile by other request
                if firstCall
                  #console.log('_getDirectory - '+e+' when trying to CREATE directory / trying one more READ: '+path)
                  return sC._getDirectory xYZ, nextDirIdx, dirReader, data, deferredModeParams, false
                else
                  console.log('_getDirectory - '+e+' when trying to CREATE directory '+path)
              sC._storeTileAsFile xYZ, dirReader, data, deferredModeParams, nextDirIdx
            )
        else
          console.log('_getDirectory - '+e+' when trying to READ directory '+path)
          sC._storeTileAsFile xYZ, dirReader, data, deferredModeParams, nextDirIdx
      )

  _storeTileAsFile: (xYZ, parentDirReader, data, deferredModeParams, failedIndex = -1) ->
    if failedIndex != -1
      console.log('error: failedIndex = '+failedIndex+' for '+xYZ)
    else if parentDirReader == null
      this._getDirectory xYZ, 2, @_dirReaders, data, deferredModeParams
    else if parentDirReader.parent.parent == null
      this._getDirectory xYZ, 0, parentDirReader, data, deferredModeParams
    else if data != null
      this._saveFile xYZ, 1, parentDirReader, data, deferredModeParams
  
  _getTileFile: (xYZ, prefetchMode, deferredModeParams, firstCall = true) ->
    path = '/'+xYZ[2]+'/'+xYZ[0]+'/'+xYZ[1]
    @_dirReaders.entry.getFile(path, {}, (fileEntry) ->
        console.log('_getTileFile - found file: '+path)
        if deferredModeParams.fileStatusCB?
          deferredModeParams.fileStatusCB deferredModeParams, false
        if @_storedFilesAreBase64
          fileEntry.file (file) ->
              #@_dirReaders.entries[xYZ[2]].entries[xYZ[0].reader
              reader = new FileReader()
              reader.onabort = (e) ->
                  console.log('aborted '+path+": "+e)
              reader.onerror = (e) ->
                  console.log('failed '+path+": "+e)
              reader.onload = (e) ->
                  if this.result == ''
                    console.log('bad read on '+path)
                  deferredModeParams.deferred.resolve this.result
          reader.readAsText(file)
          #reader.readAsDataURL(file, FileUtils.instance()._tileImageContentType)
        else
          deferredModeParams.deferred.resolve fileEntry.toURL(FileUtils.instance()._tileImageContentType)
        delete FileUtils.instance()._tileLoadQueue[FileUtils.tileKey(xYZ)]
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          if firstCall
            # check one more time if other thread stored file
            #console.log('_getTileFile - no such file / trying one more READ: '+path)
            return FileUtils.instance()._getTileFile xYZ, prefetchMode, deferredModeParams, false
          else
            console.log('_getTileFile - no such file: '+path)
        else
          console.log('error: '+e+' for '+path)
        if prefetchMode == 0
          # one mor check for asynchronous request - that's because of prefetch mit compete
          loadQueueEntry = FileUtils.instance()._tileLoadQueue[FileUtils.tileKey(xYZ)]
          unless loadQueueEntry? && (!loadQueueEntry.storeFile)
            VoyageX.MapControl.tileUrl deferredModeParams.mC, deferredModeParams.view, deferredModeParams
            loadQueueEntry.deferred = true
          else
            console.log('TODO: _getTileFile - if this is logged then loadQueueEntry-check is necessary')
        else
          if prefetchMode == 1
            VoyageX.MapControl.loadAndPrefetch deferredModeParams.mC, xYZ, deferredModeParams.view.subdomain, deferredModeParams
          else
            deferredModeParams.mC.loadReadyImage deferredModeParams.tileUrl, xYZ, deferredModeParams
      )

  _savePoiNoteAttachmentFile: (poiNote, dirReader, data, deferredModeParams) ->
    sC = FileUtils.instance()
    fileName = poiNote.id
    path = dirReader.path+'/'+fileName
    dirReader.entry.getFile(fileName, {}, (fileEntry) ->
        #unless dirReader.entries[fileName]?
        #  dirReader.entries[fileName] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
        # TODO - what is this for? is this call necessary?
        sC._storePoiNoteAttachmentAsFile poiNote, dirReader, null, deferredModeParams
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          dirReader.entry.getFile(fileName, {create: true}, (fileEntry) ->
                fileEntry.createWriter((fileWriter) ->
                  fileWriter.onwriteend = (e) ->
                      console.log('Write completed.')
                      deferredModeParams.deferred.resolve fileEntry.toURL(poiNote.attachment.content_type)
                      attachmentMeta = localStorage.getItem 'comm.poiNotes.attachmentMeta'
                      if attachmentMeta == null
                        sC._attachmentMeta = { bytes: 0, count: 0 }
                      else
                        sC._attachmentMeta = eval("(" + attachmentMeta + ")")
                      #sC._tileDB[storeKey] = data.properties.data
                      sC._attachmentMeta.count = sC._attachmentMeta.count+1
                      sC._attachmentMeta.bytes = sC._attachmentMeta.bytes+data.size
                      localStorage.setItem 'comm.poiNotes.attachmentMeta', JSON.stringify(sC._attachmentMeta)
                      #showCacheStats(sC._tileMeta.numTiles, sC._tileMeta.tilesByteSize)
                  fileWriter.onerror = (e) ->
                      console.log('Write failed: ' + e.toString())
                      #deferredModeParams.deferred.resolve deferredModeParams.tileUrl
                      deferredModeParams.deferred.resolve Storage.Model.notInCacheImage(poiNote)
                  console.log('saving file: '+path)
                  fileWriter.write(new Blob([data], {type: poiNote.attachment.content_type}))
                  # text-files
                  #fileWriter.write(data.properties.data)
                , (e) ->
                    console.log('_savePoiNoteAttachmentFile - '+e+' when trying to WRITE file '+path)
                )
            , (e) ->
                console.log('_savePoiNoteAttachmentFile - '+e+' when trying to SAVE file '+path)
            )
        else
          console.log('_savePoiNoteAttachmentFile - '+e+' when trying to STORE file '+path)
          sC._storePoiNoteAttachmentAsFile poiNote, dirReader, null, deferredModeParams
      )

  # '/poiNotes/attachments/'+poiNote.id
  # path ... ['poiNotes', 'attachments']
  _getPoiNoteDirectory: (nextDirIdx, dirReader, poiNote, data, deferredModeParams, firstCall = true) ->
    sC = FileUtils.instance()
    path = FileUtils.poiNoteAttachmentPath poiNote
    curPathDir = path[nextDirIdx]
    path = (if dirReader.parent == null then '' else dirReader.path)+'/'+curPathDir
    dirReader.entry.getDirectory(curPathDir, {}, (fileEntry) ->
        #console.log('_getPoiNoteDirectory - found directory: '+path)
        unless dirReader.entries[curPathDir]?
          dirReader.entries[curPathDir] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
        sC._storePoiNoteAttachmentAsFile poiNote, dirReader.entries[curPathDir], data, deferredModeParams
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          console.log('creating poi-note-directory: '+path)
          dirReader.entry.getDirectory(curPathDir, {create: true, exclusive: true}, (fileEntry) ->
              unless dirReader.entries[curPathDir]?
                dirReader.entries[curPathDir] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
              sC._storePoiNoteAttachmentAsFile poiNote, dirReader.entries[curPathDir], data, deferredModeParams
            , (e) ->
              if (e.code == FileError.NOT_FOUND_ERR) 
                console.log('_getPoiNoteDirectory - No such file: '+path)
              else
                # it's likely that directory has been created meanwhile by other request
                if firstCall
                  #console.log('_getPoiNoteDirectory - '+e+' when trying to CREATE directory / trying one more READ: '+path)
                  return sC._getPoiNoteDirectory nextDirIdx, dirReader, poiNote, data, deferredModeParams, false
                else
                  console.log('_getPoiNoteDirectory - '+e+' when trying to CREATE directory '+path)
              sC._storePoiNoteAttachmentAsFile poiNote, dirReader, data, deferredModeParams, nextDirIdx
            )
        else
          console.log('_getPoiNoteDirectory - '+e+' when trying to READ directory '+path)
          sC._storePoiNoteAttachmentAsFile poiNote, dirReader, data, deferredModeParams, nextDirIdx
      )

  _storePoiNoteAttachmentAsFile: (poiNote, parentDirReader, data, deferredModeParams, failedIndex = -1) ->
    if failedIndex != -1
      console.log('error: failedIndex = '+failedIndex+' for '+poiNote)
    else if parentDirReader == null
      this._getPoiNoteDirectory 0, @_dirReaders, poiNote, data, deferredModeParams
    else if parentDirReader.parent.parent == null
      this._getPoiNoteDirectory 1, parentDirReader, poiNote, data, deferredModeParams
    else if data != null
      this._savePoiNoteAttachmentFile poiNote, parentDirReader, data, deferredModeParams
  
  _getPoiNoteAttachmentFile: (poiNote, deferredModeParams) ->
    path = '/poiNotes/attachments/'+poiNote.id
    @_dirReaders.entry.getFile(path, {}, (fileEntry) ->
        console.log('_getPoiNoteAttachmentFile - found file: '+path)
        # if binary:
        #deferredModeParams.deferred.resolve fileEntry.toURL(poiNote.attachment.content_type), fileEntry.file
        fileEntry.file (file) ->
            deferredModeParams.deferred.resolve fileEntry.toURL(poiNote.attachment.content_type), new Blob([file], { type: poiNote.attachment.content_type })
#        # if text (base64):
#        fileEntry.file (file) ->
#            #@_dirReaders.entries.poiNotes.entries.attachments.reader
#            reader = new FileReader()
#            reader.onabort = (e) ->
#                console.log('aborted '+path+": "+e)
#            reader.onerror = (e) ->
#                console.log('failed '+path+": "+e)
#            reader.onload = (e) ->
#                if this.result == ''
#                  console.log('bad read on '+path)
#                deferredModeParams.deferred.resolve this.result, file
#            reader.readAsText(file)
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          console.log('_getPoiNoteAttachmentFile - no such file: '+path)
        else
          console.log('_getPoiNoteAttachmentFile - error: '+e+' for '+path)
        deferredModeParams.attachmentUrl poiNote, deferredModeParams
      )

  @instance: () ->
    @_SINGLETON
