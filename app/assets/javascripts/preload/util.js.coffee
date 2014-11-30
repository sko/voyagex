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

window.cacheStats = (statsJSON) ->
  $('#cache_stats').html('<span style="color:white;">cache-size: '+statsJSON.tilesSize+' / #'+statsJSON.numTiles+' tiles</span>')

jQuery ->
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
