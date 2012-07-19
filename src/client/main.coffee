require.config
  baseUrl: '/js'
  paths:
    text: 'lib/text'
    jade: 'lib/jade'
    jquery: 'lib/jquery'
    underscore: 'lib/underscore'
    backbone: 'lib/backbone'
    marionette: 'lib/backbone.marionette'
    relational: 'lib/backbone-relational'
    'backbone-forms': 'lib/backbone-forms'
    'backbone-forms-bootstrap': 'lib/backbone-forms.bootstrap'
    'backbone-forms-modal': 'lib/backbone-forms.bootstrap-modal'
    moment: 'lib/moment'
    hammer: 'lib/hammer'
    'jquery-hammer': 'lib/jquery.hammer'
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
    'relational': ['backbone']
    'backbone-forms-modal': ['backbone-forms']
    'jquery-hammer': ['jquery', 'hammer']
    'plugins': ['jquery']

require ['app'], (app) ->
  app.initialize()