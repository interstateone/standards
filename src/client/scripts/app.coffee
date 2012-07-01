class StandardsApp extends Backbone.Marionette.Application
  initialize: ->
    # Setup up initial state
    console.log 'test'
    @user = new User
    @layout = new AppLayout
    @router = new StandardsRouter
    @tasks = new Tasks

    _.templateSettings =
      evaluate: /\{\[([\s\S]+?)\]\}/g,
      interpolate: /\{\{([\s\S]+?)\}\}/g

    @layout.navigation.show @navigation = new NavBarView
    @layout.container.show @tasksView = new TasksView {collection}

class StandardsRouter extends Backbone.Marionette.AppRouter
  routes:
    "": "index"

  index: ->

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

class AppLayout extends Backbone.Marionette.AppLayout
  regions:
    navigation: "body > .navigation"
    container: "body > .container"

class WeekDayHeader extends Backbone.View
  template: '#weekday-header-template'

class TaskView extends Backbone.Marionette.ItemView
  tagName: 'tr'
  template: '#task-template'

class TasksView extends Backbone.Marionette.CompositeView
  tagName: 'table'
  id: 'tasksView'
  template: '#tasks-template'
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
  initialize: ->
    @template = _.template $('#navbar-template').html()

  render: ->
    renderedContent = @template
    $(@el).html renderedContent
    @