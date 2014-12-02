window.isMobile = () ->
  navigator.userAgent.match(/Mobile|webOS/) != null
  
window.showLoginDialog = (confirmEmailAddress) ->
  if confirmEmailAddress != null
    $("#sign_in_flash").html("check email-account "+confirmEmailAddress+" first for confirmation-mail")
  $("#sign_in_modal").dialog('open')


$(document).on 'keyup', '.edit_detail', (event) ->
  if (event.which == 13 || event.keyCode == 13)
    event.preventDefault()
    $(this).closest('form').submit()

window.cacheStats = () ->
  tilesSize = Math.round(Comm.StorageController.instance().getByteSize('tiles')/1024)+' kB'
  numTiles = Comm.StorageController.instance().getNumElements('tiles')
  $('#cache_stats').html('<span style="color:white;">cache-size: '+tilesSize+' / #'+numTiles+' tiles</span>')

jQuery ->
#  $.ajaxSetup({
#    headers: {
#      'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
#    }
#  })

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
