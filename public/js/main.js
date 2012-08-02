require.config({
  baseUrl: '/js',
  paths: {
    cs: 'lib/cs',
    'coffee-script': 'lib/coffee-script',
    text: 'lib/text',
    jade: 'lib/jade',
    jquery: 'lib/jquery',
    underscore: 'lib/underscore',
    backbone: 'lib/backbone',
    marionette: 'lib/backbone.marionette',
    relational: 'lib/backbone-relational',
    'backbone-forms': 'lib/backbone-forms',
    'backbone-forms-bootstrap': 'lib/backbone-forms.bootstrap',
    moment: 'lib/moment',
    hammer: 'lib/hammer',
    'jquery-hammer': 'lib/jquery.hammer',
    mobiscroll: 'lib/mobiscroll',
    plugins: 'plugins',
    app: 'app'
  },
  shim: {
    relational: ['backbone'],
    'jquery-hammer': ['jquery', 'hammer'],
    plugins: ['jquery']
  }
});

require(['cs!app'], function(app) {
  return app.initialize();
});