define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  class CheckView extends Backbone.Marionette.ItemView
    tagName: 'td'
    template: require 'jade!templates/check'
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
      @$el.html @template()
      if @model.isNew? then @$('img').addClass 'complete'
      return this
