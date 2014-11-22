if $.mobile
  # initializes touch and scroll events
  supportTouch = $.support.touch
  scrollEvent = "touchmove scroll"
  touchStartEvent = supportTouch ? "touchstart" : "mousedown"
  touchStopEvent = supportTouch ? "touchend" : "mouseup"
  touchMoveEvent = supportTouch ? "touchmove" : "mousemove"

  # handles swipeup and swipedown
  $.event.special.swipeupdown = {
      setup: () ->
        thisObject = this
        $this = $(thisObject)

        $this.bind(touchStartEvent, (event) ->
          if event.originalEvent.touches == null
            data = event
          else
            data = event.originalEvent.touches[0]
          start = {time: (new Date).getTime(),\
                   coords: [data.pageX, data.pageY],\
                   origin: $(event.target)}

          moveHandler = (event) ->
              if (!start)
                return

              if event.originalEvent.touches == null
                data = event
              else
                data = event.originalEvent.touches[0]
              stop = {time: (new Date).getTime(),\
                      coords: [data.pageX, data.pageY]}

              # prevent scrolling
              if (Math.abs(start.coords[1] - stop.coords[1]) > 10) 
                event.preventDefault()
                          

            $this.bind(touchMoveEvent, moveHandler).one(touchStopEvent, (event) ->
                          $this.unbind(touchMoveEvent, moveHandler)
                          if (start && stop) 
                              if (stop.time - start.time < 1000 && Math.abs(start.coords[1] - stop.coords[1]) > 30 && Math.abs(start.coords[0] - stop.coords[0]) < 75) 
                                  start.origin .trigger("swipeupdown") .trigger(start.coords[1] > stop.coords[1] ? "swipeup" : "swipedown")
                          start = stop = undefined
                      )
          )
    }

  # Adds the events to the jQuery events special collection
  $.each({swipedown: "swipeupdown",\
          swipeup: "swipeupdown"}, (event, sourceEvent) ->
            $.event.special[event] = {setup: () ->
                      $(this).bind(sourceEvent, $.noop)
              }
    )
else
  # scrollpane parts
  scrollPane = $(".scroll-pane")
  scrollContent = $(".scroll-content")

  # build slider
  scrollbar = $(".scroll-bar").slider({
      slide: (event, ui) ->
        if scrollContent.width() > scrollPane.width()
          scrollContent.css("margin-left", Math.round(ui.value / 100 * ( scrollPane.width() - scrollContent.width())) + "px")
        else
          scrollContent.css("margin-left", 0)
    })

  # append icon to handle
  handleHelper = scrollbar.find(".ui-slider-handle")
    .mousedown(() ->
      scrollbar.width(handleHelper.width())
    )
    .mouseup(() ->
      scrollbar.width("100%")
    )
    .append("<span class='ui-icon ui-icon-grip-dotted-vertical'></span>")
    .wrap("<div class='ui-handle-helper-parent'></div>").parent()

  # change overflow to hidden now that slider handles the scrolling
  scrollPane.css("overflow", "hidden")

  # size scrollbar and handle proportionally to scroll distance
  sizeScrollbar = () ->
    remainder = scrollContent.width() - scrollPane.width()
    proportion = remainder / scrollContent.width()
    handleSize = scrollPane.width() - (proportion * scrollPane.width())
    scrollbar.find(".ui-slider-handle").css({\
        width: handleSize,\
        "margin-left": -handleSize / 2\
      })
    handleHelper.width("").width(scrollbar.width() - handleSize)

  # reset slider value based on scroll content position
  resetValue = () ->
    remainder = scrollPane.width() - scrollContent.width()
    leftVal = scrollContent.css("margin-left") == "auto" ? 0 :
      parseInt(scrollContent.css("margin-left"))
    percentage = Math.round(leftVal / remainder * 100)
    scrollbar.slider("value", percentage)

  # if the slider is 100% and window gets larger, reveal content
  reflowContent = () ->
      showing = scrollContent.width() + parseInt(scrollContent.css("margin-left"), 10)
      gap = scrollPane.width() - showing
      if gap > 0
        scrollContent.css("margin-left", parseInt(scrollContent.css("margin-left"), 10) + gap)

  # change handle position on window resize
  $(window).resize(() ->
      resetValue()
      sizeScrollbar()
      reflowContent()
    )
  # init scrollbar size
  setTimeout(sizeScrollbar, 10) # safari wants a timeout
