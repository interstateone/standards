define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'
  require 'relational'
  window.Check = require 'cs!models/check'

  class Task extends Backbone.RelationalModel
    select: ->
      @set selected: true
      @collection.selectTask @
    relations: [
      type: Backbone.HasMany
      key: 'checks'
      relatedModel: 'Check'
      reverseRelation:
        key: 'task'
    ]

  Task.setup()

  return Task
