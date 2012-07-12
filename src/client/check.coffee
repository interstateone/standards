define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'
  require 'relational'

  class Check extends Backbone.RelationalModel
    urlRoot: '/api/checks'

  Check.setup()

  return Check