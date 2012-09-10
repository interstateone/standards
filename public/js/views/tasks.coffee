define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  TaskRowView = require 'cs!views/taskrow'

  class TasksView extends Backbone.Marionette.CompositeView
    tagName: 'table'
    id: 'tasksView'
    itemView: TaskRowView
    itemViewContainer: 'tbody'
    template: require 'jade!templates/tasks-table'
    events:
      'click a.add': 'clickedAdd'
      'keypress #newtask': 'keypressNewTask'
      'submit #newtask': 'submitNewTask'
    initialize: ->
      app.vent.on 'window:resize', => @render()
      app.vent.on 'app:changeOffset', => @render()
    templateHelpers: ->
      getWeekdaysAsArray: (full) ->
        today = moment().sod()
        if app.daysInView is 6 then startingWeekday = parseInt(app.user.get 'starting_weekday') + parseInt(app.offset ? 0)
        else startingWeekday = parseInt(today.day()) + parseInt(app.offset ? 0) - 1
        firstDayOfWeek = moment().sod()
        firstDayOfWeek.day startingWeekday
        if firstDayOfWeek.diff(today, 'days') > 0 then firstDayOfWeek.day(startingWeekday - 7)
        lengthOfWeek = if full then app.daysInView else Math.min app.daysInView, today.diff firstDayOfWeek, 'days'
        week = (firstDayOfWeek.clone().add('d', day) for day in [0..lengthOfWeek])
      date: new Date()
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
