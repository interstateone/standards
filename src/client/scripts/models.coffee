define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'
  require 'relational'

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