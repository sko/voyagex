window.isMobile = () ->
  navigator.userAgent.match(/Mobile|webOS/) != null
  
window.showLoginDialog = (confirmEmailAddress) ->
  if confirmEmailAddress != null
    $("#sign_in_flash").html("check email-account "+confirmEmailAddress+" first for confirmation-mail")
  $("#sign_in_modal").dialog('open')

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
