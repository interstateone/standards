define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'
  # require 'relational'

  class User extends Backbone.Model
    url: '/api/user/info'

    isSignedIn: (yep, nope) ->
      @fetch
        success: -> yep()
        error: -> nope()

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

  class Tasks extends Backbone.Collection
    model: Task
    url: '/api/tasks'

  class Checks extends Backbone.Collection
    model: Check

  return {User, Task, Tasks, Check, Checks}