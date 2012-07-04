define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  class User extends Backbone.Model
      url: '/api/user/info'

      isSignedIn: ->
        # Uses the HTTP status returned from the server to determine state
        @fetch
          success: -> true
          error: -> false

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

  return {User: User, Task: Task, Check: Check}