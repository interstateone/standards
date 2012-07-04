require.config
  paths:
    text: 'lib/text'
    jquery: 'lib/jquery'
    underscore: 'lib/underscore'
    backbone: 'lib/backbone'
    marionette: 'lib/backbone.marionette'
    # plugins: 'plugins'
    app: 'app'
  shim:
    'underscore':
      deps: ['jquery']
      exports: '_'
    'backbone':
      deps: ['jquery', 'underscore']
      exports: 'Backbone'
    'marionette':
      deps: ['backbone']
      exports: 'Marionette'

require ['app'], (app) ->
  app.initialize()