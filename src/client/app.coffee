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

  class Checks extends Backbone.Collection
    model: Check
    url: '/api/checks'

  Backbone.Marionette.Renderer.render = (template, data) ->
    _.template template, data

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
        app.vent.trigger 'task:uncheck', @model
      else
        app.vent.trigger 'task:check', @date
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
        @bindTo @collection, "add", @render, @
        @bindTo @collection, "sync", @render, @
        @bindTo @collection, "remove", @render, @
        @bindTo @collection, "reset", @render, @
    initialize: ->
      @collection = @model.get 'checks'
      app.vent.on 'task:check', @check, @
      app.vent.on 'task:uncheck', @uncheck, @
    showCollection: ->
      ItemView = @getItemView()
      weekdays = getWeekdaysAsArray()
      for day, index in weekdays
        check = @collection.find (check) ->
          if (check.get 'date')? then (day.diff moment check.get 'date') is 0
        boilerplate = {date: day.format('YYYY-MM-DD')}
        @addItemView check ||= boilerplate, ItemView, index
    check: (date) ->
      @collection.create date: date
    uncheck: (model) ->
      model.destroy()

  class TasksView extends Backbone.Marionette.CollectionView
    tagName: 'table'
    id: 'tasksView'
    itemView: TaskRowView
    template: require('jade!../templates/tasks-table')()
    templateHelpers: ->
      getWeekdaysAsArray: getWeekdaysAsArray
    render: ->
      @$el.html _.template @template, @serializeData()
      @showCollection()
    appendHtml: (collectionView, itemView) ->
      collectionView.$("tbody").append(itemView.el);

  class LoginView extends Form
    template: require('jade!../templates/login')()
    schema:
      email:
        validate: ['required', 'email']
      password:
        type: 'Password'
    fieldsets: [
      fields: ['email', 'password']
      legend: 'Log In'
    ]
    events:
      'submit': 'clickedLogin'
      'click .forgot': 'clickedForgot'
    clickedLogin: (e) ->
      e.preventDefault()
      e.stopPropagation()
      email = @$('#email').val()
      password = @$('#password').val()
      app.vent.trigger 'user:sign-in', email, password
    clickedForgot: (e) ->
      e.preventDefault()
      e.stopPropagation()
      email = @$('#email').val()
      app.vent.trigger 'user:forgot', email

  class NavBarView extends Backbone.Marionette.Layout
    template: require('jade!../templates/navbar')()
    initialize: ->
      app.vent.on 'scroll:window', @addDropShadow, @
      @model.on 'change', @render, @
    render: ->
      @$el.html _.template @template, @model.toJSON()
      @
    serializeData: -> {name: @model.get('name')}
    addDropShadow: ->
      if window.pageYOffset > 0 then @$el.children().addClass 'nav-drop-shadow'
      else @$el.children().removeClass 'nav-drop-shadow'

  class SettingsView extends Backbone.Marionette.Layout
    template: require('jade!../templates/settings')

  class App extends Backbone.Marionette.Application
    initialize: ->
      # Setup up initial state
      @user = new User
      @tasks = new Tasks
      @showApp()

      # @router = new AppRouter
      # Backbone.history.start
      #   pushState: true

      $(window).bind 'scroll touchmove', => @vent.trigger 'scroll:window'
      app.vent.on 'user:sign-in', @signIn, @

      app.vent.on 'task:check', @check, @
      app.vent.on 'task:uncheck', @uncheck, @
    checkAuth: ->
      console.log 'checking auth'
      @user.isSignedIn @showTasks, @showLogin, @
    signIn: (email, password) ->
      @user.signIn email, password, @showTasks, @showLogin, @
    showApp: ->
      @addRegions
        navigation: ".navigation"
        body: ".body"
      @navigation.show @navigation = new NavBarView model: @user
      @checkAuth()
    showTasks: ->
      @body.show @tasksView = new TasksView collection: @tasks
      @tasks.fetch()
    showLogin: ->
      @body.show @loginView = new LoginView
    showSettings: ->
      console.log 'settings'
      @body.show @settingsView = new SettingsView
    # check: (options) ->
    #   (@tasks.get options.task_id).get('checks').create date: options.date, task_id: options.task_id
    # uncheck: (model) ->
    #   model.destroy()

  # class AppRouter extends Backbone.Marionette.AppRouter
  #   controller: App
  #   appRoutes:
  #     "": "checkAuth"
  #     "settings": "showSettings"

  initialize = ->
     window.app = new App
     window.app.initialize()

  return initialize: initialize