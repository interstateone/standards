define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'
  require 'moment'

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

  getWeekdaysAsArray = (full) ->
    today = moment().sod()
    startingWeekday = app.user.get 'starting_weekday'
    firstDayOfWeek = moment().sod()
    firstDayOfWeek.day startingWeekday
    if firstDayOfWeek.day() > today.day() then firstDayOfWeek.day(startingWeekday - 7)
    lengthOfWeek = if full then 6 else Math.min 6, today.diff firstDayOfWeek, 'days'
    week = (firstDayOfWeek.clone().add('d', day) for day in [0..lengthOfWeek])

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
    templateHelpers: ->
      getWeekdaysAsArray: getWeekdaysAsArray
    render: ->
      @$el.html _.template @template, @serializeData()
      @showCollection()
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

  class SettingsView extends Backbone.Marionette.Layout
    template: require('jade!../templates/settings')()

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
      today = moment()

      createdDay = moment(@model.get 'created_on')
      firstDay = createdDay
      if @model.get('checks').length
        firstCheckDay = moment(@model.get('checks').sort(silent: true).first().get 'date')
        firstDay = moment(Math.min createdDay.valueOf(), firstCheckDay.valueOf())

      timeAgo = firstDay.fromNow()
      percentComplete = Math.ceil(count * 100 / today.diff firstDay, 'days')

      _.extend super,
        count: count
        percentComplete: percentComplete
        timeAgo: timeAgo
    templateHelpers:
      sentenceCase: (string) -> string.charAt(0).toUpperCase() + string.slice(1).toLowerCase()
      titleCase: (string) -> (word.charAt(0).toUpperCase() + word.slice(1).toLowerCase() for word in string.split ' ').join ' '
      pluralize: (word, count) -> word += 's' if count > 0
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

      @navBar = new NavBarView model: @user
      @tasksView = new TasksView collection: @tasks
      @settingsView = new SettingsView model: @user

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
      app.vent.on 'task:check', @check, @
      app.vent.on 'task:uncheck', @uncheck, @
      app.vent.on 'error', @showError, @

      # Routes
      app.vent.on 'task:clicked', @showTask, @
      app.vent.on 'task:delete', @deleteTask, @
      app.vent.on 'settings:clicked', @showSettings, @
      app.vent.on 'home:clicked', @showTasks, @
    showApp: ->
      @addRegions
        navigation: '.navigation'
        body: '.body'
      @flash = new MultiRegion el: '.flash'
      @navigation.show @navBar
    showTasks: ->
      @router.navigate ''
      @body.show @tasksView = new TasksView collection: @tasks
    showSettings: ->
      @router.navigate 'settings'
      @body.show @settingsView = new SettingsView model: @user
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
    showError: (message) -> @flash.append @error = new ErrorView message: message
    hideErrors: -> @flash.close()
    showNotice: (message) -> @flash.append @notice = new NoticeView message: message
    # check: (options) ->
    #   (@tasks.get options.task_id).get('checks').create date: options.date, task_id: options.task_id
    # uncheck: (model) ->
    #   model.destroy()

  class AppRouter extends Backbone.Marionette.AppRouter
    appRoutes:
      '': 'showTasks'
      'settings': 'showSettings'
      'task/:id': 'showTask'

  initialize = ->
     window.app = new App
     window.app.initialize()

  return initialize: initialize