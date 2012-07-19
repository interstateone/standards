define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'
  require 'moment'
  require 'jquery-hammer'

  # App Libs
  require 'plugins'

  # App Components
  User = require 'user'
  Task = require 'task'
  Form = require 'form'

  class Tasks extends Backbone.Collection
    model: Task
    url: '/api/tasks'
    selectTask: (task) ->
      app.vent.trigger 'task:clicked', task.id

  class Checks extends Backbone.Collection
    model: Check
    url: '/api/checks'

  Backbone.Marionette.Renderer.render = (template, data) ->
    _.template template, data

  # Map JS reset() function to jQuery
  jQuery.fn.reset = ->
    $(this).each -> this.reset()

  heatmapHeader = ->
    firstDayOfWeek = moment().sod().day 0
    week = (firstDayOfWeek.clone().add('d', day) for day in [0..6])

  getWeekdaysAsArray = (full) ->
    today = moment().sod()
    if app.daysInView is 6 then startingWeekday = parseInt(app.user.get 'starting_weekday') + parseInt(app.offset ? 0)
    else startingWeekday = parseInt(today.day()) + parseInt(app.offset ? 0) - 1
    firstDayOfWeek = moment().sod()
    firstDayOfWeek.day startingWeekday
    if firstDayOfWeek.diff(today, 'days') > 0 then firstDayOfWeek.day(startingWeekday - 7)
    lengthOfWeek = if full then app.daysInView else Math.min app.daysInView, today.diff firstDayOfWeek, 'days'
    week = (firstDayOfWeek.clone().add('d', day) for day in [0..lengthOfWeek])

  colorArray = (numberOfRows) ->
    colors = []
    for i in [0..numberOfRows]
      hue = i * 340 / (numberOfRows + 2)
      saturation = 0.8
      lightness = 0.5
      alpha = 1.0
      color = $.Color({hue: hue, saturation: saturation, lightness: lightness, alpha: alpha}).toHslaString()
      colors.push($.Color(color).toHexString())
    colors

  renderColors = ->
    rows = $('tbody').children()
    bgColors = colorArray(rows.size(), 0.8)
    barColors = colorArray(rows.size(), 0.6)
    $(rows).each (row) ->
      $ministat = $(this).children('td.title').children('.ministat')
      $ministat.css("background-color", bgColors[row])
      $ministat.children('.minibar').css("background-color", barColors[row])

  class CheckView extends Backbone.Marionette.ItemView
    tagName: 'td'
    template: require('jade!../templates/check')()
    initialize: ->
      if @model.isNew? then @date = @model.get 'date'
      else _.extend @, @model
    events:
      'click': 'toggleCheck'
    toggleCheck: ->
      if @model.isNew?
        @trigger 'task:uncheck', @model
      else
        @trigger 'task:check', @date
    render: ->
      @$el.html @template
      if @model.isNew? then @$('img').addClass 'complete'
      @

  class TaskRowView extends Backbone.Marionette.CompositeView
    tagName: 'tr'
    template: require('jade!../templates/task-row')()
    itemView: CheckView
    initialEvents: ->
      if @collection?
        @bindTo @collection, 'add', @render, @
        @bindTo @collection, 'sync', @render, @
        @bindTo @collection, 'remove', @render, @
        @bindTo @collection, 'reset', @render, @
    initialize: ->
      @collection = @model.get 'checks'
      @collection.comparator = (check) -> check.get 'date'
      @on 'itemview:task:check', @check, @
      @on 'itemview:task:uncheck', @uncheck, @
    events:
      'click .task': 'clickedTask'
    clickedTask: (e) ->
      e.preventDefault()
      console.log 'clicked', @model.id
      @model.select()
    onRender: -> @renderHeight()
    renderCollection: ->
      @triggerBeforeRender()
      @closeChildren()
      @showCollection()
      @triggerRendered()
      @trigger "composite:collection:rendered"
    showCollection: ->
      ItemView = @getItemView()
      weekdays = getWeekdaysAsArray()
      for day, index in weekdays
        check = @collection.find (check) ->
          if (check.get 'date')? then (day.diff moment check.get 'date') is 0
        boilerplate = {date: day.format('YYYY-MM-DD')}
        @addItemView check ||= boilerplate, ItemView, index
    check: (itemView, date) ->
      @collection.create date: date
    uncheck: (itemView, model) ->
      model.destroy()
    renderHeight: ->
      count = @model.get('checks').length
      createdDay = moment(@model.get 'created_on')
      firstDay = createdDay.valueOf()
      if @model.get('checks').length
        firstCheckDay = moment(@model.get('checks').sort(silent: true).first().get 'date')
        firstDay = Math.min createdDay.valueOf(), firstCheckDay.valueOf()
      today = moment().sod()
      total = (today.diff (moment firstDay), 'days') + 1
      # console.log 'created', createdDay, 'firstCheckDay', firstCheckDay, 'first day', moment(firstDay), 'count', count, 'total', total
      # console.log @collection.pluck 'date'
      @$('.minibar').css "height", Math.min 50 * count / total, 50

  class TasksView extends Backbone.Marionette.CompositeView
    tagName: 'table'
    id: 'tasksView'
    itemView: TaskRowView
    itemViewContainer: 'tbody'
    template: require('jade!../templates/tasks-table')()
    events:
      'click a.add': 'clickedAdd'
      'keypress #newtask': 'keypressNewTask'
      'submit #newtask': 'submitNewTask'
    initialize: ->
      app.vent.on 'window:resize', => @render()
      app.vent.on 'app:changeOffset', => @render()
    templateHelpers: ->
      getWeekdaysAsArray: getWeekdaysAsArray
    clickedAdd: ->
      @toggleNewTaskButton()
      @toggleNewTaskForm()
    toggleNewTaskButton: ->
      unless @$('i').hasClass('cancel')
        @$('i').animate({transform: 'rotate(45deg)'}, 'fast').toggleClass('cancel')
      else
        @$('i').animate({transform: ''}, 'fast').toggleClass('cancel')
    toggleNewTaskForm: ->
      if @$('#newtask').css('opacity') is '0'
        @$('#newtask').animate(opacity: 1, 'fast').css 'visibility', 'visible'
      else
        @$('#newtask').animate({opacity: 0}, 'fast').reset().css 'visibility', 'hidden'
    keypressNewTask: (e) ->
      key = if (e.which)? then e.which else e.keyCode
      if key == 13
        e.preventDefault()
        e.stopPropagation()
        $('#newtask').submit()
        _gaq.push(['_trackEvent', 'task', 'create'])
    submitNewTask: (e) ->
      e.preventDefault()
      title = @$('input#title').val()
      purpose = @$('input#purpose').val()
      @collection.create title: title, purpose: purpose

      # Remove welcome message after submitting first task
      # $('.hero-unit').hide()

      # renderColors()

      @toggleNewTaskButton()
      @toggleNewTaskForm()

  class NavBarView extends Backbone.Marionette.ItemView
    template: require('jade!../templates/navbar')()
    events:
      'click .brand': 'clickedHome'
      'click .settings': 'clickedSettings'
      'click .moveForward': 'clickedMoveForward'
      'click .moveBackward': 'clickedMoveBackward'
    initialize: ->
      app.vent.on 'scroll:window', @addDropShadow, @
    addDropShadow: ->
      if window.pageYOffset > 0 then @$el.children().addClass 'nav-drop-shadow'
      else @$el.children().removeClass 'nav-drop-shadow'
    clickedHome: (e) ->
      e.preventDefault()
      app.vent.trigger 'home:clicked'
    clickedSettings: (e) ->
      e.preventDefault()
      app.vent.trigger 'settings:clicked'
    clickedMoveForward: ->
      app.vent.trigger 'app:moveForward'
    clickedMoveBackward: ->
      app.vent.trigger 'app:moveBackward'

  class SettingsView extends Backbone.Marionette.Layout
    template: require('jade!../templates/settings')()
    regions:
      info: '.info'
      password: '.password'

  class ButtonRadio extends Backbone.Form.editors.Select
    tagName: 'div'
    events:
      'click button': 'clickedButton'
    render: ->
      el = super
      @updateButtons()
      el
    updateButtons: ->
      @$('button').each (index, button) => if $(button).val() is @getValue() then $(button).addClass 'active'
    clickedButton: (e) ->
      @setValue $(e.target).val()
      @$('button').each (index, button) => if $(button).val() is @getValue() then $(button).addClass 'active'
    getValue: -> @$('input').val()
    setValue: (value) -> @$('input').val value ? @getValue()
    _arrayToHtml: (array) ->
      html = []

      html.push '<div class="btn-group" data-toggle="buttons-radio" data-toggle-name="starting_weekday" name="starting_weekday">'

      _.each array, (option, index) =>
        if _.isObject option
          val = option.val ? ''
          itemHtml = '<button type="button" class="btn" name="'+@id+'" value="'+val+'" id="'+@id+'-'+index+'" data-toggle="button">'+option.label+'</button>'
        else
          itemHtml = '<button type="button" class="btn" name="'+@id+'" value="'+option+'" id="'+@id+'-'+index+'" data-toggle="button">'+option.label+'</button>'
        html.push itemHtml

      html.push '''
        </div>
        <input type="hidden" name="starting_weekday">
        '''

      html.join ''

  class Timezone extends Backbone.Form.editors.Select
    tagName: 'div'
    events:
      'change select': 'resetButton'
      'click button': 'getLocation'
    render: ->
      options = @schema.options

      if options instanceof Backbone.Collection
        collection = options
        if collection.length > 0
          @renderOptions options
        else
          collection.fetch
            success: (collection) =>
              @renderOptions options
      else if _.isFunction options
        options (result) =>
          @renderOptions result
          @disableButton()
      else @renderOptions options
      @
    disableButton: -> unless navigator.geolocation? then @$('button').attr 'disabled', 'disabled'
    resetButton: -> @$('button').css 'color', '#333333'
    getLocation: ->
      $button = @$ 'button'
      unless $button.attr('disabled')?
        navigator.geolocation.getCurrentPosition (position) =>
            # lookup in geonames
            lat = position.coords.latitude
            long = position.coords.longitude
            urlbase = "http://api.geonames.org/timezoneJSON?"
            username = "interstateone"

            url = urlbase + "lat=" + lat + "&" + "lng=" + long + "&" + "username=" + username

            $.get url, (data) =>
              $button.css('color', 'green')
              @setValue data.timezoneId
            .error -> $button.css('color', 'red')
          # error function
          (error) ->
            switch (error.code)
              when error.TIMEOUT then app.trigger 'error', 'Geolocation error: Timeout'
              when error.POSITION_UNAVAILABLE then app.trigger 'error', 'Geolocation error: Position unavailable'
              when error.PERMISSION_DENIED then app.trigger 'error', 'Geolocation error: Permission denied'
              when error.UNKNOWN_ERROR then app.trigger 'error', 'Geolocation error: Unknown error'
          timeout: 5000
    getValue: -> @$('select').val()
    setValue: (value) -> @$('select').val value
    _arrayToHtml: (array) ->
      html = []

      html.push '<select id="timezone" name="timezone">'

      _.each array, (option) ->
        if _.isObject option then html.push "<option value=\"#{ option.val ? '' }\">#{ option.label }</option>"
        else html.push "<option>#{ option }</option>"

      html.push '''
        </select>
        <button class="btn geolocate" type="button"><i class="icon-map-marker"></i></button>
        '''

      html.join ''

  class InfoForm extends Form
    template: require('jade!../templates/info-form')()
    events:
      'click button[type="submit"]': 'commitChanges'
    commitChanges: (e) ->
      e.preventDefault()
      e.stopPropagation()
      errors = @commit()
      unless errors? then @model.save {}, success: -> app.vent.trigger 'notice', 'Your info has been updated.'
    schema:
      name:
        title: 'Name'
        type: 'Text'
        validators: ['required']
      email:
        title: 'Email'
        type: 'Text'
        validators: ['email', 'required']
      starting_weekday:
        title: 'Weeks start on'
        type: ButtonRadio
        options: (callback) -> callback(val: day, label: moment().day(day).format('ddd').slice 0,1 for day in [0..6])
      timezone:
        title: 'Timezone'
        type: Timezone
        options: (callback) ->
          $.get '/api/timezones', (data) ->
            result = _.map data, (obj) ->
              val: _.keys(obj)[0]
              label: _.values(obj)[0]
            callback result
      email_permission:
        title: 'Do you want to receive email updates about Standards?'
        type: 'Checkbox'
    fieldsets: [
      legend: 'Info'
      fields: ['name', 'email', 'starting_weekday', 'timezone', 'email_permission']
    ]

  class PasswordForm extends Form
    template: require('jade!../templates/password-form')()
    events:
      'click button[type="submit"]': 'commitChanges'
    commitChanges: (e) ->
      e.preventDefault()
      e.stopPropagation()
      errors = @validate()
      unless errors? then $.ajax
        url: '/api/user/password'
        type: 'POST'
        data: JSON.stringify
          current_password: @$('input[name="current_password"]').val()
          new_password: @$('input[name="new_password"]').val()
        success: -> app.vent.trigger 'notice', 'Your password has been updated.'
    schema:
      current_password:
        title: 'Current Password'
        type: 'Password'
      new_password:
        title: 'New Password'
        type: 'Password'
        validators: [
          (value, formValues) ->
            lengthError =
              type: 'Password'
              message: 'Password must be at least 8 characters long.'
            if value.length < 8 then lengthError
        ]
    fieldsets: [
      legend: 'Change Password'
      fields: ['current_password', 'new_password']
    ]


  class ErrorView extends Backbone.Marionette.View
    template: require('jade!../templates/error-flash')()
    render: ->
      @$el.html _.template @template, @serializeData()
    serializeData: ->
      message: @options.message

  class NoticeView extends Backbone.Marionette.View
    template: require('jade!../templates/notice-flash')()
    render: ->
      @$el.html _.template @template, @serializeData()
    serializeData: ->
      message: @options.message

  class TaskView extends Backbone.Marionette.ItemView
    template: require('jade!../templates/taskview')()
    events:
      'click a.delete': 'clickedDelete'
      'click a.delete-confirm': 'confirmDelete'
    clickedDelete: ->
      @$(".deleteModal").modal()
    confirmDelete: (e) ->
      e.preventDefault()
      @$('.delete-confirm').button('loading')
      app.vent.trigger 'task:delete', @model.id
    serializeData: ->
      count = @model.get('checks').length
      today = moment().sod()

      @model.get('checks').comparator = (check) -> check.get 'date'

      createdDay = moment(@model.get 'created_on').sod()
      firstDay = createdDay
      if @model.get('checks').length
        firstCheckDay = moment(@model.get('checks').sort(silent: true).first().get 'date')
        firstDay = moment(Math.min createdDay.valueOf(), firstCheckDay.valueOf())

      percentComplete = Math.ceil(count * 100 / (today.diff(firstDay, 'days') + 1))
      timeAgo = if today.diff(firstDay, 'hours') > 24 then firstDay.fromNow() else 'today'
      console.log today.diff(firstDay, 'hours')
      weekdayCount = @weekdayCount()
      heatmap = @heatmap weekdayCount

      _.extend super,
        count: count
        percentComplete: percentComplete
        timeAgo: timeAgo
        heatmap: heatmap
    weekdayCount: ->
      weekdayCount = [0,0,0,0,0,0,0]
      @model.get('checks').each (check) ->
        weekdayIndex = moment(check.get('date')).day()
        weekdayCount[weekdayIndex] += 1
      weekdayCount
    heatmap: (countArray) ->
      heatmap = []
      max = _.max countArray
      max ||= 1
      min = _.min countArray
      for count in countArray
        temp = $.Color('#FF0000').hue(Math.abs(count - max) / max * 40)
        heatmap.push count: count, temp: temp.toHexString()
      heatmap
    templateHelpers:
      sentenceCase: (string) -> string.charAt(0).toUpperCase() + string.slice(1).toLowerCase()
      titleCase: (string) -> (word.charAt(0).toUpperCase() + word.slice(1).toLowerCase() for word in string.split ' ').join ' '
      pluralize: (word, count) -> word += 's' if count > 0
      heatmapHeader: heatmapHeader
      getWeekdaysAsArray: getWeekdaysAsArray
      gsub: (source, pattern, replacement) ->
        result = ''

        if _.isString pattern then pattern = RegExp.escape pattern

        unless pattern.length || pattern.source
          replacement = replacement ''
          replacement + source.split('').join(replacement) + replacement

        while source.length > 0
          if match = source.match pattern
            result += source.slice 0, match.index
            result += replacement match
            source = source.slice(match.index + match[0].length)
          else
            result += source
            source = ''
        result
      switchPronouns: (string) ->
        this.gsub string, /\b(I am|You are|I|You|Your|My)\b/i, (pronoun) ->
          switch pronoun[0].toLowerCase()
            when 'i' then 'you'
            when 'you' then 'I'
            when 'i am' then "You are"
            when 'you are' then 'I am'
            when 'your' then 'my'
            when 'my' then 'your'

  class MultiRegion extends Backbone.Marionette.Region
    open: (view) ->
      @$el.append view.el
    close: ->
      view = @currentView
      unless (view? or view.length > 0) then return
      unless _.isArray view then @currentView = view = [view]

      _.each view, (v) ->
        if v.close then v.close()
        @trigger("view:closed", v)
      , this

      @currentView = []

      @$el.empty()
    append: (view) ->
      @ensureEl()

      view.render()
      @open view

      if view.onShow then view.onShow()
      view.trigger "show"

      if @onShow then @onShow view
      @trigger "view:show", view

      @currentView ?= []

      unless _.isArray @currentView then @currentView = [@currentView]

      @currentView.push view

  class App extends Backbone.Marionette.Application
    initialize: ->
      # Setup up initial state
      @user = new User
      @tasks = new Tasks
      if window.bootstrap.user? then @user.set window.bootstrap.user
      if window.bootstrap.tasks? then @tasks.reset window.bootstrap.tasks
      @daysInView = 6
      @offset = 0

      @navBar = new NavBarView model: @user
      @tasksView = new TasksView collection: @tasks
      @settingsView = new SettingsView model: @user

      @toggleWidth()
      @showApp()

      @router = new AppRouter controller: @
      Backbone.history.start
        pushState: true

      $(document).ajaxError (e, xhr, settings, error) ->
        switch xhr.status
          when 401 then app.vent.trigger 'error', 'Authentication error, try logging in again.'
          when 404 then app.vent.trigger 'error', 'The server didn\'t understand that action.'
          when 500 then app.vent.trigger 'error', 'There was a server error, try again.'

      # Events
      $(window).bind 'scroll touchmove', => @vent.trigger 'scroll:window'
      $(window).bind 'resize', => @toggleWidth()


      app.vent.on 'task:check', @check, @
      app.vent.on 'task:uncheck', @uncheck, @
      app.vent.on 'error', @showError, @
      app.vent.on 'notice', @showNotice, @

      # Routes
      app.vent.on 'task:clicked', @showTask, @
      app.vent.on 'task:delete', @deleteTask, @
      app.vent.on 'settings:clicked', @showSettings, @
      app.vent.on 'home:clicked', @showTasks, @
      app.vent.on 'app:moveForward', @moveForward, @
      app.vent.on 'app:moveBackward', @moveBackward, @
    toggleWidth: ->
      old = @daysInView
      @daysInView = if $(window).width() <= 480 then 1 else 6
      unless @daysInView is old then app.vent.trigger 'window:resize'
    showApp: ->
      @addRegions
        navigation: '.navigation'
        body: '.body'
      @flash = new MultiRegion el: '.flash'
      @navigation.show @navBar
      $(@body.el).hammer().bind 'swipe', (ev) =>
        switch ev.direction
          when 'left' then @vent.trigger 'app:moveForward'
          when 'right' then @vent.trigger 'app:moveBackward'
    showTasks: ->
      @offset = 0
      @router.navigate ''
      @body.show @tasksView = new TasksView collection: @tasks
    showSettings: ->
      @router.navigate 'settings'
      @body.show @settingsView = new SettingsView
      @settingsView.info.show @infoForm = new InfoForm model: @user
      @settingsView.password.show @passwordForm = new PasswordForm
    showTask: (id) ->
      task = @tasks.get id
      unless task?
        @showTasks()
        @showError 'That task doesn\'t exist.'
      else
        @router.navigate "task/#{ task.id }"
        @body.show @taskView = new TaskView model: task
    deleteTask: (id) ->
      @tasks.get(id).destroy
        success: =>
          $(".deleteModal").modal 'hide'
          @showTasks()
    showError: (message) -> @flash.append error = new ErrorView message: message
    showNotice: (message) ->
      @flash.append notice = new NoticeView message: message
      window.setTimeout (=> notice.$(".alert").alert('close')), 2000
    hideErrors: -> @flash.close()
    moveForward: ->
      unless @offset is 0
        if @daysInView is 1 then @offset += 1
        else @offset += 7
        @vent.trigger 'app:changeOffset'
    moveBackward: ->
      if @daysInView is 1 then @offset -= 1
      else @offset -= 7
      @vent.trigger 'app:changeOffset'

  class AppRouter extends Backbone.Marionette.AppRouter
    appRoutes:
      '': 'showTasks'
      'settings': 'showSettings'
      'task/:id': 'showTask'

  initialize = ->
     window.app = new App
     window.app.initialize()

  return initialize: initialize