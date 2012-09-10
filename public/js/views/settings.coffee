define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  Form = require 'cs!views/form'
  {ButtonRadio, Timezone, Hour} = require 'cs!views/editors'

  class InfoForm extends Form
    template: require('jade!templates/info-form')()
    events:
      'click button[type="submit"]': 'commitChanges'
    commitChanges: (e) ->
      e.preventDefault()
      e.stopPropagation()
      errors = @commit()
      unless errors? then @model.save {}, success: ->
        app.vent.trigger 'notice', 'Your info has been updated.'
    schema:
      name:
        title: 'Name'
        type: 'Text'
        validators: ['required']
      email:
        title: 'Email'
        type: 'Text'
        validators: ['email', 'required']
      starting_weekday:
        title: 'Weeks start on'
        type: ButtonRadio
        options: (callback) -> callback
          val: day
          label: moment().day(day).format('ddd').slice 0,1 for day in [0..6]
      timezone:
        title: 'Timezone'
        type: Timezone
        options: (callback) ->
          result = _.map bootstrap.timezones, (obj) ->
            val: _.keys(obj)[0]
            label: _.values(obj)[0]
          callback result
      daily_reminder_permission:
        title: 'Remind me each day if I haven\'t checked anything off yet'
        type: 'Checkbox'
      daily_reminder_time:
        title: 'Reminder time'
        type: Hour
      email_permission:
        title: 'Do you want to receive email updates about Standards?'
        type: 'Checkbox'
    fieldsets: [
      legend: 'Info'
      fields: [
        'name'
        'email'
        'starting_weekday'
        'timezone'
        'daily_reminder_permission'
        'daily_reminder_time'
        'email_permission'
      ]
    ]

  class PasswordForm extends Form
    template: require('jade!../templates/password-form')()
    events:
      'click button[type="submit"]': 'commitChanges'
    commitChanges: (e) ->
      e.preventDefault()
      e.stopPropagation()
      errors = @validate()
      unless errors? then $.ajax
        url: '/api/user/password'
        type: 'POST'
        data: JSON.stringify
          current_password: @$('input[name="current_password"]').val()
          new_password: @$('input[name="new_password"]').val()
        success: -> app.vent.trigger 'notice', 'Your password has been updated.'
    schema:
      current_password:
        title: 'Current Password'
        type: 'Password'
      new_password:
        title: 'New Password'
        type: 'Password'
        validators: [
          (value, formValues) ->
            lengthError =
              type: 'Password'
              message: 'Password must be at least 8 characters long.'
            if value.length < 8 then lengthError
        ]
    fieldsets: [
      legend: 'Change Password'
      fields: ['current_password', 'new_password']
    ]

  class SettingsView extends Backbone.Marionette.Layout
    template: require 'jade!../templates/settings'
    regions:
      info: '.info'
      password: '.password'
    onRender: ->
      @info.show new InfoForm model: @user
      @password.show new PasswordForm
