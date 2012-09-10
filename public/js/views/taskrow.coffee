define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  CheckView = require 'cs!views/check'
  string = require 'cs!string'

  getWeekdaysAsArray = (full) ->
        today = moment().sod()
        if app.daysInView is 6 then startingWeekday = parseInt(app.user.get 'starting_weekday') + parseInt(app.offset ? 0)
        else startingWeekday = parseInt(today.day()) + parseInt(app.offset ? 0) - 1
        firstDayOfWeek = moment().sod()
        firstDayOfWeek.day startingWeekday
        if firstDayOfWeek.diff(today, 'days') > 0 then firstDayOfWeek.day(startingWeekday - 7)
        lengthOfWeek = if full then app.daysInView else Math.min app.daysInView, today.diff firstDayOfWeek, 'days'
        week = (firstDayOfWeek.clone().add('d', day) for day in [0..lengthOfWeek])

  class TaskRowView extends Backbone.Marionette.CompositeView
    tagName: 'tr'
    template: require 'jade!templates/task-row'
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
    events:
      'click .task': 'clickedTask'
    clickedTask: (e) ->
      e.preventDefault()
      console.log 'clicked', @model.id
      @model.select()
    templateHelpers: ->
      titleCase: string.titleCase
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
      @$('.minibar').css "height", Math.min 50 * count / total, 50
