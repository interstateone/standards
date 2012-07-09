define (require) ->

    # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'

  require 'backbone-forms'
  require 'backbone-forms-bootstrap'

  class Form extends Backbone.Form
    initialize: (options) ->
      _.extend options ?= {},
        schema: @schema
        template: @template
        fieldsets: @fieldsets
      super options
    render: ->
      options = @options
      template = @template ? Form.templates[options.template]

      # Create el from template
      if _.isFunction template then $form = $ template fieldsets: '<b class="bbf-tmp"></b>'
      else $form = $ _.template template, fieldsets: '<b class="bbf-tmp"></b>'

      # Render fieldsets
      $fieldsetContainer = $ '.bbf-tmp', $form

      _.each options.fieldsets, (fieldset) =>
        $fieldsetContainer.append @renderFieldset fieldset

      $fieldsetContainer.children().unwrap()

      # Set the template contents as the main element; removes the wrapper element
      @setElement $form
      @