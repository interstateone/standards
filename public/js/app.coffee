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
  User = require 'cs!models/user'
  Task = require 'cs!models/task'

  NavBarView = require 'cs!views/navbar'
  TasksView = require 'cs!views/tasks'
  TaskView = require 'cs!views/task'
  SettingsView = require 'cs!views/settings'

  class Tasks extends Backbone.Collection
    model: Task
    url: '/api/tasks'
    selectTask: (task) ->
      app.vent.trigger 'task:clicked', task.id

  class Checks extends Backbone.Collection
    model: Check
    url: '/api/checks'

  Backbone.Marionette.Renderer.render = (template, data) -> template(data)

  # Map JS reset() function to jQuery
  jQuery.fn.reset = ->
    $(this).each -> this.reset()

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

  class ErrorView extends Backbone.Marionette.View
    template: require 'jade!templates/error-flash'
    render: ->
      @$el.html @template @serializeData()
    serializeData: ->
      message: @options.message

  class NoticeView extends Backbone.Marionette.View
    template: require 'jade!templates/notice-flash'
    render: ->
      @$el.html @template @serializeData()
    serializeData: ->
      message: @options.message

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

      $(document).ajaxError (e, xhr, settings, error) =>
        switch xhr.status
          when 401 then @vent.trigger 'error', 'Authentication error, try logging in again.'
          when 404 then @vent.trigger 'error', 'The server didn\'t understand that action.'
          when 500 then @vent.trigger 'error', 'There was a server error, try again.'

      $(document).on 'click tap', 'a[href="/logout"]', (event) ->
        event.preventDefault()
        window.location = $(this).attr "href"

      new FastClick document.body

      # Events
      $(window).bind 'scroll touchmove', => @vent.trigger 'scroll:window'
      $(window).bind 'resize', => @toggleWidth()
      $(window).bind 'keyup', (e) =>
        key = e.which ? e.keyCode
        switch key
          when 37 then @vent.trigger 'app:moveBackward'
          when 39 then @vent.trigger 'app:moveForward'

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
    showTasks: ->
      @offset = 0
      @router.navigate ''
      @navBar.showArrows()
      @body.show @tasksView = new TasksView collection: @tasks
      $(@tasksView.el).hammer().bind 'swipe', (ev) =>
        switch ev.direction
          when 'left' then @vent.trigger 'app:moveForward'
          when 'right' then @vent.trigger 'app:moveBackward'
    showSettings: ->
      @router.navigate 'settings'
      @navBar.hideArrows()
      @body.show @settingsView = new SettingsView model: @user
    showTask: (id) ->
      task = @tasks.get id
      unless task?
        @showTasks()
        @showError 'That task doesn\'t exist.'
      else
        @router.navigate "task/#{ task.id }"
        @navBar.hideArrows()
        @body.show @taskView = new TaskView model: task
    deleteTask: (id) ->
      @tasks.get(id).destroy
        success: =>
          $(".deleteModal").modal 'hide'
          @showTasks()
    showError: (message) ->
      @flash.append error = new ErrorView message: message
      window.setTimeout (=> error.$(".alert").alert('close')), 2000
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
      'settings': 'showSettings'
      'task/:id': 'showTask'
      '*anything': 'showTasks'

  initialize = ->
     window.app = new App
     window.app.initialize()

  return {initialize}
