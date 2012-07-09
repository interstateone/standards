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
  {User, Task, Tasks, Check, Checks} = require 'models'
  Form = require 'form'

  Backbone.Marionette.Renderer.render = (template, data) ->
    _.template template, data

  getWeekdaysAsArray: ->
    today = moment()
    startingWeekday = app.user.get 'starting_weekday'
    firstDayOfWeek = moment()
    firstDayOfWeek.day startingWeekday
    if firstDayOfWeek.day() > today.day() then firstDayOfWeek.day(startingWeekday - 7)
    week = (firstDayOfWeek.clone().add('d', day) for day in [0..6])

  class TaskView extends Backbone.Marionette.ItemView
    tagName: 'tr'
    template: require('jade!../templates/task-row')()

  class TasksView extends Backbone.Marionette.CollectionView
    tagName: 'table'
    id: 'tasksView'
    itemView: TaskView
    template: require('jade!../templates/tasks-table')()
    templateHelpers: ->
      getWeekdaysAsArray: @getWeekdaysAsArray
    render: ->
      @$el.html _.template @template, @serializeData()
      @showCollection()
    appendHtml: (collectionView, itemView) ->
      collectionView.$("tbody").append(itemView.el);
    getWeekdaysAsArray: ->
      today = moment()
      startingWeekday = app.user.get 'starting_weekday'
      firstDayOfWeek = moment()
      firstDayOfWeek.day startingWeekday
      if firstDayOfWeek.day() > today.day() then firstDayOfWeek.day(startingWeekday - 7)
      week = (firstDayOfWeek.clone().add('d', day) for day in [0..6])

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

  class CheckView extends Backbone.Marionette.ItemView
    tagname: 'a'
    initialize: ->
      @template = _.template $('#check-template').html()

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

  # class AppRouter extends Backbone.Marionette.AppRouter
  #   controller: App
  #   appRoutes:
  #     "": "checkAuth"
  #     "settings": "showSettings"

  initialize = ->
     window.app = new App
     window.app.initialize()

  return initialize: initialize