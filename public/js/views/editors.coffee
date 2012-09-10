define (require) ->

  # Vendor Libs
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Marionette = require 'marionette'

  Form = require 'cs!views/form'

  class ButtonRadio extends Backbone.Form.editors.Select
    tagName: 'div'
    events:
      'click button': 'clickedButton'
    render: ->
      el = super
      @updateButtons()
      el
    updateButtons: ->
      @$('button').each (index, button) =>
        if $(button).val() is @getValue() then $(button).addClass 'active'
    clickedButton: (e) ->
      @setValue $(e.target).val()
      @$('button').each (index, button) =>
        if $(button).val() is @getValue() then $(button).addClass 'active'
    getValue: -> @$('input').val()
    setValue: (value) -> @$('input').val value ? @getValue()
    _arrayToHtml: (array) ->
      html = []

      html.push '''<div class="btn-group"
                        data-toggle="buttons-radio"
                        data-toggle-name="starting_weekday"
                        name="starting_weekday">'''

      _.each array, (option, index) =>
        if _.isObject option
          val = option.val ? ''
          itemHtml = """<button type=\"button\"
                                class=\"btn\"
                                name=\"#{ @id }\"
                                value=\"#{ val }\"
                                id=\"#{ @id }-#{ index}\"
                                data-toggle=\"button\">
                                  #{ option.label }
                                </button>"""
        else
          itemHtml = """<button type=\"button\"
                                class=\"btn\"
                                name=\"#{ @id }\"
                                value=\"#{ option }\"
                                id=\"#{ @id }-#{ index }\"
                                data-toggle=\"button\">
                                  #{ option.label }
                                </button>"""
        html.push itemHtml

      html.push '''
        </div>
        <input type="hidden" name="starting_weekday">
        '''

      html.join ''

  class Timezone extends Backbone.Form.editors.Select
    tagName: 'div'
    events:
      'change select': 'resetButton'
      'click button': 'getLocation'
    render: ->
      options = @schema.options

      if options instanceof Backbone.Collection
        collection = options
        if collection.length > 0
          @renderOptions options
        else
          collection.fetch
            success: (collection) =>
              @renderOptions options
      else if _.isFunction options
        options (result) =>
          @renderOptions result
          @disableButton()
      else @renderOptions options
      @
    disableButton: ->
      unless navigator.geolocation?
        @$('button').attr 'disabled', 'disabled'
    resetButton: -> @$('button').css 'color', '#333333'
    getLocation: ->
      $button = @$ 'button'
      unless $button.attr('disabled')?
        navigator.geolocation.getCurrentPosition (position) =>
            # lookup in geonames
            lat = position.coords.latitude
            long = position.coords.longitude
            urlbase = "http://api.geonames.org/timezoneJSON?"
            username = "interstateone"

            url = "#{ urlbase }lat=#{ lat }&lng=#{ long }&username=#{ username }"

            $.get url, (data) =>
              $button.css('color', 'green')
              @setValue data.timezoneId
            .error -> $button.css('color', 'red')
          # error function
          (error) ->
            switch (error.code)
              when error.TIMEOUT
                app.trigger 'error', 'Geolocation error: Timeout'
              when error.POSITION_UNAVAILABLE
                app.trigger 'error', 'Geolocation error: Position unavailable'
              when error.PERMISSION_DENIED
                app.trigger 'error', 'Geolocation error: Permission denied'
              when error.UNKNOWN_ERROR
                app.trigger 'error', 'Geolocation error: Unknown error'
          timeout: 5000
    getValue: -> @$('select').val()
    setValue: (value) -> @$('select').val value
    _arrayToHtml: (array) ->
      html = []

      html.push '<div class="input-append"><select id="timezone" name="timezone">'

      _.each array, (option) ->
        if _.isObject option
          html.push "<option value=\"#{ option.val ? '' }\">#{ option.label }</option>"
        else html.push "<option>#{ option }</option>"

      html.push '''
        </select>
        <button class="btn add-on" type="button">
          <i class="icon-map-marker"></i>
        </button>
        </div>
        '''

      html.join ''

  class Hour extends Backbone.Form.editors.Base
    getValue: ->
      data = @$el.scroller('getValue')
      hours = parseInt data[0]
      if parseInt(data[1]) is 1 then hours += 12
      hours
    setValue: (value) ->
      if value > 11
        hour = value - 12
        pm = 1
      else
        hour = value
        pm = 0
      @$el.scroller('setValue', [hour, pm], true)
    initialize: ->
      super
      @$el.scroller
        preset: 'time'
        display: 'inline'
        mode: 'mixed'
        rows: 3
        height: 30
        width: 50
        timeWheels: 'hA'
        showLabel: false
    render: ->
      @setValue @value
      @

  return ButtonRadio: ButtonRadio, Timezone: Timezone, Hour: Hour
