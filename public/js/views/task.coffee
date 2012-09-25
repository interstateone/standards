define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  string = require 'cs!string'

  heatmapHeader = ->
    firstDayOfWeek = moment().sod().day 0
    week = (firstDayOfWeek.clone().add('d', day) for day in [0..6])

  class TaskView extends Backbone.Marionette.ItemView
    template: require 'jade!templates/taskview'
    events:
      'click a.delete': 'clickedDelete'
      'click a.delete-confirm': 'confirmDelete'
      'click a.edit-title': 'editTitle'
      'click a.confirm-update-title': 'updateTitle'
      'click a.cancel-update-title': 'removeUpdateForm'
    clickedDelete: ->
      @$(".deleteModal").modal()
    confirmDelete: (e) ->
      e.preventDefault()
      @$('.delete-confirm').button('loading')
      app.vent.trigger 'task:delete', @model.id
    editTitle: ->
      @$('h2').find('span').replaceWith('<input type="text" class="input-medium title" />')
      @$('input.title').val(@model.get 'title').focus()
      @$('.edit-title').hide()
      @$('input.title').after('<a class="cancel-update-title"><i class="edit-button icon-remove-sign"></i></a>')
      @$('input.title').after('<a class="confirm-update-title"><i class="edit-button icon-ok-sign"></i></a>')
      @$el.on 'keydown', 'input', (event) =>
        key = if (event.which)? then event.which else event.keyCode
        if key is 13 then @updateTitle()
        else if key is 27 then @removeUpdateForm()
    removeUpdateForm: ->
      @$('input.title').replaceWith('<span />')
      @$('h2').find('span').text @model.get('title')
      @$('a.cancel-update-title').remove()
      @$('a.confirm-update-title').remove()
      @$('.edit-title').show()
    updateTitle: ->
      @model.set 'title', @$('input.title').val()
      @model.save {}, success: => @removeUpdateForm()
    serializeData: ->
      count = @model.get('checks').length
      today = moment().sod()

      @model.get('checks').comparator = (check) -> check.get 'date'

      createdDay = moment(@model.get 'created_on').sod()
      firstDay = createdDay
      if @model.get('checks').length
        firstCheckDay = moment(@model.get('checks').sort(silent: true).first().get 'date')
        firstDay = moment(Math.min createdDay.valueOf(), firstCheckDay.valueOf())

      percentComplete = Math.ceil(count * 100 / (today.diff(firstDay, 'days') + 1))
      timeAgo = firstDay.fromNow()
      console.log today.diff(firstDay, 'hours')
      weekdayCount = @weekdayCount()
      heatmap = @heatmap weekdayCount

      _.extend super,
        count: count
        percentComplete: percentComplete
        timeAgo: timeAgo
        heatmap: heatmap
    weekdayCount: ->
      weekdayCount = [0,0,0,0,0,0,0]
      @model.get('checks').each (check) ->
        weekdayIndex = moment(check.get('date')).day()
        weekdayCount[weekdayIndex] += 1
      weekdayCount
    heatmap: (countArray) ->
      heatmap = []
      max = _.max countArray
      max ||= 1
      min = _.min countArray
      for count in countArray
        temp = $.Color('#FF0000').hue(Math.abs(count - max) / (max - min) * 40)
        heatmap.push count: count, temp: temp.toHexString()
      heatmap
    templateHelpers:
      sentenceCase: string.sentenceCase
      titleCase: string.titleCase
      pluralize: string.pluralize
      gsub: string.gsub
      heatmapHeader: heatmapHeader
      getWeekdaysAsArray: (full) ->
        today = moment().sod()
        if app.daysInView is 6 then startingWeekday = parseInt(app.user.get 'starting_weekday') + parseInt(app.offset ? 0)
        else startingWeekday = parseInt(today.day()) + parseInt(app.offset ? 0) - 1
        firstDayOfWeek = moment().sod()
        firstDayOfWeek.day startingWeekday
        if firstDayOfWeek.diff(today, 'days') > 0 then firstDayOfWeek.day(startingWeekday - 7)
        lengthOfWeek = if full then app.daysInView else Math.min app.daysInView, today.diff firstDayOfWeek, 'days'
        week = (firstDayOfWeek.clone().add('d', day) for day in [0..lengthOfWeek])
      switchPronouns: (string) ->
        this.gsub string, /\b(I am|You are|I|You|Your|My)\b/i, (pronoun) ->
          switch pronoun[0].toLowerCase()
            when 'i' then 'you'
            when 'you' then 'I'
            when 'i am' then "You are"
            when 'you are' then 'I am'
            when 'your' then 'my'
            when 'my' then 'your'
