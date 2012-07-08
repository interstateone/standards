define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  # App Libs
  require 'plugins'

  # App Components
  {User, Task, Tasks, Check, Checks} = require 'models'

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

  class LoginView extends Backbone.Marionette.ItemView
    template: require('jade!../templates/login')()
    render: ->
      @$el.html @template
      @
    events:
      'submit': 'clickedLogin'
    clickedLogin: (e) ->
      e.preventDefault()
      e.stopPropagation()
      email = @$('#email').val()
      password = @$('#password').val()
      app.vent.trigger 'user:sign-in', email, password

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

  class AppRouter extends Backbone.Marionette.AppRouter
    controller: App

  class App extends Backbone.Marionette.Application
    initialize: ->
      # Setup up initial state
      @user = new User
      @tasks = new Tasks
      @showApp()

      $(window).bind 'scroll touchmove', => @vent.trigger 'scroll:window'
      app.vent.on 'user:sign-in', @signIn, @

      @user.isSignedIn @showTasks, @showLogin, @
    showApp: ->
      @addRegions
        navigation: ".navigation"
        body: ".body"
      @navigation.show @navigation = new NavBarView model: @user
    showTasks: ->
      @body.show @tasksView = new TasksView collection: @tasks
      @tasks.fetch()
    showLogin: ->
      @body.show @loginView = new LoginView
    signIn: (email, password) ->
      @user.signIn email, password, @showTasks, @showLogin, @

  initialize = ->
     window.app = new App
     window.app.initialize()

  return initialize: initialize