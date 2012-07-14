// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(function(require) {
    var $, Backbone, Check, Marionette, _;
    $ = require('jquery');
    _ = require('underscore');
    Backbone = require('backbone');
    Marionette = require('marionette');
    require('relational');
    Check = (function(_super) {

      __extends(Check, _super);

      function Check() {
        return Check.__super__.constructor.apply(this, arguments);
      }

      Check.prototype.urlRoot = '/api/checks';

      return Check;

    })(Backbone.RelationalModel);
    Check.setup();
    return Check;
  });

}).call(this);