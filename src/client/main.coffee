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
    moment: 'lib/moment'
    hammer: 'lib/hammer'
    'jquery-hammer': 'lib/jquery.hammer'
    plugins: 'plugins'
    app: 'app'
  shim:
    relational: ['backbone']
    'jquery-hammer': ['jquery', 'hammer']
    plugins: ['jquery']

require ['app'], (app) ->
  app.initialize()