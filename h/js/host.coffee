$ = Annotator.$

class Annotator.Host extends Annotator.Guest
  # Drag state variables
  drag:
    delta: 0
    enabled: false
    last: null
    tick: false

  constructor: (element, options) ->
    # Create the iframe
    if document.baseURI and window.PDFView?
      # XXX: Hack around PDF.js resource: origin. Bug in jschannel?
      hostOrigin = '*'
    else
      hostOrigin = window.location.origin
      # XXX: Hack for missing window.location.origin in FF
      hostOrigin ?= window.location.protocol + "//" + window.location.host

    app = $('<iframe></iframe>')
    .attr('seamless', '')
    .attr('src', "#{options.app}#/?xdm=#{encodeURIComponent(hostOrigin)}")

    super

    app.appendTo(@frame)

    if @toolbar?
      @toolbar.addClass 'annotator-hide'
      app
      .on('mouseenter', => @toolbar.removeClass 'annotator-hide')
      .on('mouseleave', => @toolbar.addClass 'annotator-hide')

    if @plugins.Heatmap?
      this._setupDragEvents()
      @plugins.Heatmap.element.on 'click', (event) =>
        if @frame.hasClass 'annotator-collapsed'
          this.showFrame()
        else
          this.hideFrame()

  _setupXDM: (options) ->
    channel = super

    channel

    .bind('showFrame', (ctx, routeName) =>
      unless @drag.enabled
        @frame.css 'margin-left': "#{-1 * @frame.width()}px"
      @frame.removeClass 'annotator-no-transition'
      @frame.removeClass 'annotator-collapsed'

      switch routeName
        when 'editor'
          this.publish 'annotationEditorShown'
        when 'viewer'
          this.publish 'annotationViewerShown'
    )

    .bind('hideFrame', (ctx, routeName) =>
      @frame.css 'margin-left': ''
      @frame.removeClass 'annotator-no-transition'
      @frame.addClass 'annotator-collapsed'

      switch routeName
        when 'editor'
          this.publish 'annotationEditorHidden'
        when 'viewer'
          this.publish 'annotationViewerHidden'
    )

    .bind('dragFrame', (ctx, screenX) => this._dragUpdate screenX)

    .bind('getMaxBottom', =>
      sel = '*' + (":not(.annotator-#{x})" for x in [
        'adder', 'outer', 'notice', 'filter', 'frame'
      ]).join('')

      # use the maximum bottom position in the page
      all = for el in $(document.body).find(sel)
        p = $(el).css('position')
        t = $(el).offset().top
        z = $(el).css('z-index')
        if (y = /\d+/.exec($(el).css('top'))?[0])
          t = Math.min(Number y, t)
        if (p == 'absolute' or p == 'fixed') and t == 0 and z != 'auto'
          bottom = $(el).outerHeight(false)
          # but don't go larger than 80, because this isn't bulletproof
          if bottom > 80 then 0 else bottom
        else
          0
      Math.max.apply(Math, all)
    )

  _setupDragEvents: ->
    el = document.createElementNS 'http://www.w3.org/1999/xhtml', 'canvas'
    el.width = el.height = 1
    @element.append el

    handle = @plugins.Heatmap.element[0]
    handle.draggable = true

    handle.addEventListener 'dragstart', (event) =>
      event.dataTransfer.dropEffect = 'none'
      event.dataTransfer.effectAllowed = 'none'
      event.dataTransfer.setData 'text/plain', ''
      event.dataTransfer.setDragImage el, 0, 0
      @drag.enabled = true
      @drag.last = event.screenX

      m = parseInt (getComputedStyle @frame[0]).marginLeft
      @frame.css
        'margin-left': "#{m}px"
      this.showFrame()

    handle.addEventListener 'dragend', (event) =>
      @drag.enabled = false
      @drag.last = null

    document.addEventListener 'dragover', (event) =>
      this._dragUpdate event.screenX

  _dragUpdate: (screenX) =>
    unless @drag.enabled then return
    if @drag.last?
      @drag.delta += screenX - @drag.last
    @drag.last = screenX
    unless @drag.tick
      @drag.tick = true
      window.requestAnimationFrame this._dragRefresh

  _dragRefresh: =>
    d = @drag.delta
    @drag.delta = 0
    @drag.tick = false

    m = parseInt (getComputedStyle @frame[0]).marginLeft
    w = -1 * m
    m += d
    w -= d

    @frame.addClass 'annotator-no-transition'
    @frame.css
      'margin-left': "#{m}px"
      width: "#{w}px"


  addToken: (token) =>
    @api.notify
      method: 'addToken'
      params: token

  onAdderClick: (event) =>
    """
    Differs from upstream in a few ways:
    - Don't fire annotationCreated events: that's the job of the sidebar
    - Save the event for retriggering if login interrupts the flow
    """
    event?.preventDefault()

    # Save the event for restarting edit
    @event = event

    # Hide the adder
    @adder.hide()
    position = @adder.position()

    # Show a temporary highlight so the user can see what they selected
    # Also extract the quotation and serialize the ranges
    annotation = this.setupAnnotation(this.createAnnotation())
    $(annotation.highlights).addClass('annotator-hl-temporary')

    # Subscribe to the editor events

    # Make the highlights permanent if the annotation is saved
    save = =>
      do cleanup
      $(annotation.highlights).removeClass('annotator-hl-temporary')

    # Remove the highlights if the edit is cancelled
    cancel = =>
      do cleanup
      this.deleteAnnotation(annotation)

    # Don't leak handlers at the end
    cleanup = =>
      this.unsubscribe('annotationEditorHidden', cancel)
      this.unsubscribe('annotationEditorSubmit', save)

    this.subscribe('annotationEditorHidden', cancel)
    this.subscribe('annotationEditorSubmit', save)

    # Display the editor.
    this.showEditor(annotation, position)
