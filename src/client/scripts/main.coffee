require.config
  paths:
    jquery: 'lib/jquery'
    underscore: 'lib/underscore'
    backbone: 'lib/backbone'
    marionette: 'lib/backbone.marionette'
    # plugins: 'plugins'
    app: 'app'
  shim:
    'backbone':
      deps: ['jquery', 'underscore']
      exports: 'Backbone'
    'marionette':
      deps: ['backbone']
      exports: 'Marionette'

require ['jquery', 'app'], ($) ->
  $ ->
    app = new StandardsApp
    app.initialize()