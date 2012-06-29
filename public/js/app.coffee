Standards = new Backbone.Marionette.Application

Standards.addRegions
  container: "body > .container"

Standards.addInitializer (options) ->
  tasks = new Tasks()
  tasks.fetch
    success: (collection, response) ->
      tasksView = new TasksView {collection}
      Standards.container.show tasksView

_.templateSettings =
  interpolate: /\{\{([\s\S]+?)\}\}/g

class User extends Backbone.Model
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

class Tasks extends Backbone.Collection
  model: Task
  url: '/api/tasks'

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

class Check extends Backbone.Model
  url: "/check"

class CheckView extends Backbone.View
  tagname: 'a'
  initialize: ->
    @template = _.template $('#check-template').html()

  render: ->
    renderedContent = @template @model.toJSON()
    $(@el).html renderedContent
    @

class StandardsRouter extends Backbone.Router
  routes:
    "": "index"

  index: ->
    tasks = new Tasks
    tasks.fetch
      success: (collection, response) ->
        tasksView = new TasksView { collection }
        $('body').append tasksView.render().el

$ ->
  Standards.start()