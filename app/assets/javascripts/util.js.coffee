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

  # http://localhost:3005/users/confirmation?confirmation_token=mbZqkG9UEghCAVSsxd9F
  exec = document.location.search.match(/exec=([^&]*)/, '$1')
  if exec != null
    if exec[1] == 'show_login_dialog'
      $("#sign_in_modal").dialog('open')
