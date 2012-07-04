define (require) ->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  class User extends Backbone.Model
    url: '/api/user/info'

    isSignedIn: ->
      !this.isNew()

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

    render: ->
      renderedContent = @template @model.toJSON()
      $(@el).html renderedContent
      @

  class NavBarView extends Backbone.Marionette.Layout
    template: require 'text!templates/navbar.html'
    render: ->
      @$el.html _.template @template, @serializeData()
      @
    serializeData: -> { title: app.title, name: @model.get('name') }
    initialize: ->
      app.vent.on 'scroll:window', @addDropShadow, @
    addDropShadow: ->
      if window.pageYOffset > 0 then @$el.children().addClass 'nav-drop-shadow'
      else @$el.children().removeClass 'nav-drop-shadow'

  class App extends Backbone.Marionette.Application
    initialize: ->
      # Setup up initial state
      @title = 'Standards'
      @user = new User
      @user.fetch
        success: =>
          @tasks = new Tasks
          @tasks.fetch()

          @addRegions
            main: 'body'
          @main.show @layout = new AppLayout

          @layout.navigation.show @navigation = new NavBarView model: @user
          @layout.body.show @tasksView = new TasksView collection: @tasks

      $(window).bind 'scroll touchmove', => @vent.trigger 'scroll:window'

  initialize = ->
    _.templateSettings =
      evaluate: /\{\[([\s\S]+?)\]\}/g
      interpolate: /\{\{([\s\S]+?)\}\}/g

    window.app = new App
    window.app.initialize()

  return initialize: initialize