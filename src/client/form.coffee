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
        tagName: @tagName
        className: @className
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

      $el = $ document.createElement if options.tagName? then options.tagName else 'div'
      $el.addClass options.className if options.className?
      $el.html $form

      # Render fieldsets
      $fieldsetContainer = $ '.bbf-tmp', $el
      $fieldsetContainer.append @renderFieldset fieldset for fieldset in options.fieldsets

      # Set the template contents as the main element; removes the wrapper element
      @setElement $el
      @