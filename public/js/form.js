// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(function(require) {
    var $, Backbone, Form, _;
    $ = require('jquery');
    _ = require('underscore');
    Backbone = require('backbone');
    require('backbone-forms');
    require('backbone-forms-bootstrap');
    return Form = (function(_super) {

      __extends(Form, _super);

      function Form() {
        return Form.__super__.constructor.apply(this, arguments);
      }

      Form.prototype.initialize = function(options) {
        _.extend(options != null ? options : options = {}, {
          tagName: this.tagName,
          className: this.className,
          schema: this.schema,
          template: this.template,
          fieldsets: this.fieldsets
        });
        return Form.__super__.initialize.call(this, options);
      };

      Form.prototype.render = function() {
        var $el, $fieldsetContainer, $form, fieldset, options, template, _i, _len, _ref, _ref1;
        options = this.options;
        template = (_ref = this.template) != null ? _ref : Form.templates[options.template];
        if (_.isFunction(template)) {
          $form = $(template({
            fieldsets: '<b class="bbf-tmp"></b>'
          }));
        } else {
          $form = $(_.template(template, {
            fieldsets: '<b class="bbf-tmp"></b>'
          }));
        }
        $el = $(document.createElement(options.tagName != null ? options.tagName : 'div'));
        if (options.className != null) {
          $el.addClass(options.className);
        }
        $el.html($form);
        $fieldsetContainer = $('.bbf-tmp', $el);
        _ref1 = options.fieldsets;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          fieldset = _ref1[_i];
          $fieldsetContainer.append(this.renderFieldset(fieldset));
        }
        this.setElement($el);
        return this;
      };

      return Form;

    })(Backbone.Form);
  });

}).call(this);