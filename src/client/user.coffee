define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  class User extends Backbone.Model
    url: '/api/user/info'

    isSignedIn: (yep, nope, context) ->
      @fetch
        success: $.proxy yep, context
        error: $.proxy nope, context
    signIn: (e, p, onSucceed, onFail, context) ->
      $.ajax
        url: '/api/sign-in'
        type: 'POST'
        dataType: 'json'
        data: { email: e, password: p }
        error: $.proxy onFail, context
        success: (data) =>
          @set data
          onSucceed.call context
        context: @
    signOut: ->
      $.ajax
        url       : '/api/sign-out'
        type      : 'POST'
      .done ->
        @clear()
        @trigger 'signed-out'
    forgot: (e) ->
      $.ajax
        url: '/api/user/forgot'
        type: 'POST'
        dataType: ''