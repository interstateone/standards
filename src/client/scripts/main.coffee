require.config
  paths:
    text: 'lib/text'
    jade: 'lib/jade'
    jquery: 'lib/jquery'
    underscore: 'lib/underscore'
    backbone: 'lib/backbone'
    marionette: 'lib/backbone.marionette'
    relational: 'lib/backbone-relational'
    moment: 'lib/moment'
    plugins: 'plugins'
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
    'relational':
      deps: ['underscore', 'backbone']
    'plugins':
      deps: ['jquery']

require ['app'], (app) ->
  app.initialize()