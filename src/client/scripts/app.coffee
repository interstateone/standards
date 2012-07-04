define (require) ->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'
  require 'plugins'

  class User extends Backbone.Model
    url: '/api/user/info'

    isSignedIn: ->
      # Uses the HTTP status returned from the server to determine state
      @fetch
        success: -> true
        error: -> false

    signIn: (email, password, onFail, onSucceed) ->
      $.ajax
        url       : '/sign-in'
        method    : 'POST'
        dataType  : 'json'
        data      : { email: email, password: password }
        error     : onFail
        success   : onSucceed
        context   : @
      @

    signOut: ->
      $.ajax
        url       : '/sign-out'
        method    : 'POST'
      .done ->
        @clear()
        @trigger 'signed-out'

  class Task extends Backbone.Model
    url: "/task"

  class Check extends Backbone.Model
    url: "/check"

  class Tasks extends Backbone.Collection
    model: Task
    url: '/api/tasks'

  class AppLayout extends Backbone.Marionette.Layout
    template: require 'text!templates/app.html'
    regions:
      navigation: ".navigation"
      body: ".body"
    render: ->
      @el.innerHTML = @template
      @

  class WeekDayHeader extends Backbone.View
    template: '#weekday-header-template'

  class TaskView extends Backbone.Marionette.ItemView
    tagName: 'tr'
    template: '#task-template'

  class TasksView extends Backbone.Marionette.CollectionView
    tagName: 'table'
    id: 'tasksView'
    itemView: TaskView

    appendHtml: (collectionView, itemView) ->
      collectionView.$("tbody").append(itemView.el);

  class CheckView extends Backbone.Marionette.ItemView
    tagname: 'a'
    initialize: ->
      @template = _.template $('#check-template').html()

  class NavBarView extends Backbone.Marionette.Layout
    template: require 'text!templates/navbar.html'
    initialize: ->
      app.vent.on 'scroll:window', @addDropShadow, @
      @model.bind 'change', @render, @
    render: ->
      @$el.html _.template @template, @model.toJSON()
      @
    serializeData: -> {name: @model.get('name')}
    addDropShadow: ->
      if window.pageYOffset > 0 then @$el.children().addClass 'nav-drop-shadow'
      else @$el.children().removeClass 'nav-drop-shadow'

  class App extends Backbone.Marionette.Application
    initialize: ->
      # Setup up initial state
      @user = new User
      @showApp()

      if @user.isSignedIn() then @showTasks()
      else @showLogin()

      $(window).bind 'scroll touchmove', => @vent.trigger 'scroll:window'

    showApp: ->
      @addRegions
        main: 'body'
      @main.show @layout = new AppLayout
      @layout.navigation.show @navigation = new NavBarView model: @user
    showTasks: ->
      @user.fetch()
      @layout.body.show @tasksView = new TasksView model: @tasks = new Tasks
      @tasks.fetch()
    showLogin: ->
      # @layout.body.show @loginView = new LoginView

  initialize = ->
    _.templateSettings =
      evaluate: /\{\[([\s\S]+?)\]\}/g
      interpolate: /\{\{([\s\S]+?)\}\}/g

    window.app = new App
    window.app.initialize()

  return initialize: initialize