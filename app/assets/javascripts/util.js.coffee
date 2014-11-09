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
