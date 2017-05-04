#= require models/data/query
#= require models/data/project
#= require models/data/account
#= require models/data/preferences
#= require models/ui/temporal
#= require models/ui/project_list
#= require models/ui/service_options_list
#= require models/ui/account_form
#= require models/ui/feedback

data = @edsc.models.data
ui = @edsc.models.ui
ns = @edsc.models.page

@edsc.help = do ($=jQuery, config=@edsc.config, wait = @edsc.util.xhr.wait, page=@edsc.page, preferences = @edsc.models.data.preferences, PreferencesModel = data.Preferences) ->

  tourOptions =
    tour_end:
      title: 'Tour Ended'
      element: '#main-toolbar h1 a'
      placement: 'bottom'
      content: 'Your tour has ended.  At any point you may restart it by visiting the home page and clicking
                on the "Take a Tour" link.'

  defaultTemplate = "<div class='popover tour'>
                <div class='arrow'></div>
                <h3 class='popover-title'></h3>
                <div class='popover-content'></div>
                <div class='popover-navigation'>
                  <div class='btn-group'>
                    <button class='button-small button-outline' data-role='prev'>« Prev</button>
                    <button class='button-small' data-role='next'>Next <i class='fa fa-arrow-circle-right'></i></button>
                  </div>
                  <button class='button-small button-outline' data-role='end'>Close</button>
                </div>
              </div>"

  arrowFreeTemplate = "<div class='popover tour'>
                <h3 class='popover-title'></h3>
                <div class='popover-content'></div>
                <div class='popover-navigation'>
                  <div class='btn-group'>
                    <button class='button-small button-outline' data-role='prev'>« Prev</button>
                    <button class='button-small' data-role='next'>Next <i class='fa fa-arrow-circle-right'></i></button>
                  </div>
                  <button class='button-small button-outline' data-role='end'>Close</button>
                </div>
              </div>"

  tour = [{
      title: "Welcome to Earthdata Search Client"
      content: 'This application allows you to search, discover, visualize, refine, and access NASA Earth Observation data.  
                If you are new to this application, please follow the brief tour to get an overview of the features that will 
                help you achieve your goals.'
      element: '#map-center'
      placement: 'left'
      showNext: true
      showPrevious: false
      template: arrowFreeTemplate
      cleanup: (nextFn, closeFn) ->
        $(window).off 'statechange anchorchange', closeFn
      advanceHook: (nextFn, closeFn) ->
        $(window).one 'statechange anchorchange', closeFn
    }, {
      title: "Search"
      content: '<div>Use Earthdata Search Clients natural language processing-enabled search tool to quickly narrow
                down to relevant collections.  An example search phrase could be "Land Surface Temperature over
                Texas last month".  Results will be displayed in the collection panel below.</div>
                <div style="margin-top: 5px;">If you would prefer to draw spatial boundaries, upload a shapefile, or pick a temporal range from
                a calendar, use the buttons to the right of the search box.</div>
                <div style="margin-top: 5px;">To start your search session over, click the eraser icon to clear all of your set filters.</div>
                '
      element: '#keywords'
      placement: 'bottom'
      showNext: true
      cleanup: (nextFn, closeFn) ->
        $(window).off 'statechange anchorchange', closeFn
      advanceHook: (nextFn, closeFn) ->
        $(window).one 'statechange anchorchange', closeFn
    }, 
    {
      title: "Search Results"
      content: '<div>Search results will be shown in the Matching Collections panel below.  Each result will have summary 
                information along with relevant badges to allow you to quickly scan your search results to find the
                right collection for you.  The panel can be resized by clicking and dragging the bar above the "Matching
                Collections" tab.</div>
                <div style="margin-top: 5px;">To view more information about a collection, click on the “i” icon.</div>
                <div style="margin-top: 5px;">To view granules available for download, click anywhere on a collection.</div>
                <div style="margin-top: 5px;">Click on the + icon to add a collection to a project, which allows you to compare multiple collections.</div>
'
      element: '#collection-results-list'
      placement: 'top'
      showNext: true
      cleanup: (nextFn, closeFn) ->
        $(window).off 'statechange anchorchange', closeFn
      advanceHook: (nextFn, closeFn) ->
        $(window).one 'statechange anchorchange', closeFn
    },{
      title: "Facets"
      content: "Refine your search further with available 'keyword' facets."
      element: "#master-overlay-parent"
      placement: 'right'
      showNext: true
      top: null
      positionHook: (positionFn) ->
        positionFn("#master-overlay-parent .master-overlay-content")
    }, {
      title: "Map Tools"
      content: 'Use these standard map tools to configure and position the map as well as enable certain spatial search tools.'
      placement: 'left'
      element: '.leaflet-control-zoom-in'
      showNext: true
      positionHook: (positionFn) ->
        positionFn("#master-overlay-parent .master-overlay-content")
    }, {
      title: 'Toolbar'
      content: 'Use the options available (upon logging in) in the application toolbar to view recent downloads, saved projects, and profile 
      information. You can provide feedback using our feedback module. '
      element: '.user-info'
      placement: 'bottom'
    }]

  

  defaultHelpOptions =
    placement: 'auto left'
    html: true
    trigger: 'manual'
    template: defaultTemplate
    container: 'body'

  defaultTourOptions =
    reflex: true
    placement: 'left'

  queue = []
  shown = {}
  index = 0
  next = null
  close = null

  tourRunning = false

  hideCurrent = ->
    if queue[index]?
      queue[index].cleanup?(next, close)
      $(queue[index].element).popover('destroy')
      $('.popover-advance').removeClass('popover-advance')

  close = ->
    hideCurrent()
    queue = []
    index = 0
    tourRunning = false

  prev = ->
    if index > 0
      hideCurrent()
      index--
      showCurrent()

  next = ->
    if index < queue.length - 1
      hideCurrent()
      index++
      showCurrent()
    else
      close()

  position = (selector)->
    $(selector).on 'scroll', (e) ->
      if index == 2 || index == 3 || index == 5 || index == 6 || index == 13
        $container = $(this)
        $tour_popover = $('.popover.tour')
        queue[index].top = $tour_popover.offset().top unless queue[index].top?
        $tour_popover.css({top: queue[index].top - $(this).scrollTop()})

  showCurrentImmediate = ->
    $('.popover-advance').removeClass('popover-advance')

    $el = $(queue[index].element)

    if $el.length > 1
      console.error "Too many elements matched selector #{queue[index].element}.  Showing the first.", $el
      $el = $el.first()

    $el.popover(queue[index])
    $el.attr('data-original-title', '')
    $el.popover('show')
    shown[queue[index].key] = true

    unless queue[index].advanceHook
      $(queue[index].target ? $el).addClass('popover-advance')

    # console.log "Popover: #{queue[index].element} -> #{$el.length}"

    queue[index].advanceHook?(next, close)
    queue[index].closeHook?(close)
    queue[index].positionHook?(position)

    if $el.data('bs.popover')?
      $tip = $el.data('bs.popover').$tip
      $tip.toggleClass('is-popover-single', queue.length == 1)
      if tourRunning
        $tip.find('[data-role=end]').text('End Tour')
        $tip.find('[data-role=prev]').hide()
        $tip.find('[data-role=next]').toggle(queue[index].showNext)
      else
        $tip.find('[data-role=end]').text('Close')
        $tip.find('[data-role=prev]').toggle(index != 0)
        $tip.find('[data-role=next]').toggle(index != queue.length - 1)

  showCurrent = ->
    if queue[index].wait
      wait(showCurrentImmediate)
    else if queue[index].waitOnAnimate
      setTimeout((-> wait(showCurrentImmediate)), config.defaultAnimationDurationMs + 200)
    else
      showCurrentImmediate()

  $(document).on 'click', '.popover [data-role=prev]', prev
  $(document).on 'click', '.popover [data-role=next], .popover-advance', next
  $(document).on 'click', '.popover [data-role=end]', ->
    if tourRunning
      preferences = new PreferencesModel()
      preferences.showTour(false)
      preferences.save()
      close()
      add('tour_end')
    else
      close()

  $(document).on 'click', '.show-tour', (e) ->
    unless window.edscportal
      e.preventDefault()
      startTour()

  add = (key, options={}) ->
    unless tourRunning
      options = $.extend({}, defaultHelpOptions, tourOptions[key], options, key: key)
      for item in queue
        return if item.key == key
      unless options.once && shown[key]
        queue.push(options)
        showCurrent()

  remove = (key) ->
    if queue[0]?.key == key
      next()
    else
      queue = (item for item in queue when item.key != key)

  current = ->
    if tourRunning then nil else queue[index]

  startTour = ->
    close()
    tourRunning = true

    for stop, i in tour
      options = $.extend({}, defaultHelpOptions, stop, key: "tour_#{i}")
      queue.push(options)

    showCurrent()

  exports =
    add: add
    remove: remove
    current: current
    next: next
    prev: prev
    close: close
    startTour: startTour
