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
    regions:
      'dropdown': 'ul.nav'
    initialize: ->
      app.vent.on 'scroll:window', @addDropShadow, @
    addDropShadow: ->
      if window.pageYOffset > 0 then @$el.children().addClass 'nav-drop-shadow'
      else @$el.children().removeClass 'nav-drop-shadow'

  class UserDropdown extends Backbone.Marionette.ItemView
    tagName: 'li'
    className: 'dropdown'
    template: require('jade!../templates/user-dropdown')()
    initialize: ->
      @model.on 'change', @render, @
    render: ->
      @$el.html _.template @template, @model.toJSON()
      @

  class LoginDropdown extends Form
    tagName: 'li'
    className: 'dropdown'
    template: require('jade!../templates/login-dropdown')()
    schema:
      email:
        validate: ['required', 'email']
      password:
        type: 'Password'
    fieldsets: [ fields: ['email', 'password'] ]
    events:
      'submit': 'clickedLogin'
      'click [type="submit"]': 'clickedLogin'
      'click li': 'clicked'
      'click .forgot': 'clickedForgot'
    clicked: (e) ->
      e.stopPropagation()
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

  class SettingsView extends Backbone.Marionette.Layout
    template: require('jade!../templates/settings')

  class App extends Backbone.Marionette.Application
    initialize: ->
      # Setup up initial state
      @user = new User
      @tasks = new Tasks

      @navBar = new NavBarView
      @tasksView = new TasksView collection: @tasks
      @loginDropdown = new LoginDropdown
      @userDropdown = new UserDropdown model: @user
      @settingsView = new SettingsView model: @user

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
      @navigation.show @navBar
      @checkAuth()
    showTasks: ->
      @body.show @tasksView
      @tasks.fetch()
      @navBar.dropdown.show @userDropdown
    showLogin: ->
      @navBar.dropdown.show @loginDropdown
    showSettings: ->
      console.log 'settings'
      @body.show @settingsView
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