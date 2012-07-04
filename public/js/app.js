// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(function(require) {
    var $, App, AppLayout, Backbone, Check, CheckView, Marionette, NavBarView, Task, TaskView, Tasks, TasksView, User, WeekDayHeader, initialize, _, _ref;
    $ = require('jquery');
    _ = require('underscore');
    Backbone = require('backbone');
    Marionette = require('marionette');
    require('plugins');
    _ref = require('models'), User = _ref.User, Task = _ref.Task, Check = _ref.Check;
    Tasks = (function(_super) {

      __extends(Tasks, _super);

      function Tasks() {
        return Tasks.__super__.constructor.apply(this, arguments);
      }

      Tasks.prototype.model = Task;

      Tasks.prototype.url = '/api/tasks';

      return Tasks;

    })(Backbone.Collection);
    AppLayout = (function(_super) {

      __extends(AppLayout, _super);

      function AppLayout() {
        return AppLayout.__super__.constructor.apply(this, arguments);
      }

      AppLayout.prototype.template = require('text!templates/app.html');

      AppLayout.prototype.regions = {
        navigation: ".navigation",
        body: ".body"
      };

      AppLayout.prototype.render = function() {
        this.el.innerHTML = this.template;
        return this;
      };

      return AppLayout;

    })(Backbone.Marionette.Layout);
    WeekDayHeader = (function(_super) {

      __extends(WeekDayHeader, _super);

      function WeekDayHeader() {
        return WeekDayHeader.__super__.constructor.apply(this, arguments);
      }

      WeekDayHeader.prototype.template = '#weekday-header-template';

      return WeekDayHeader;

    })(Backbone.View);
    TaskView = (function(_super) {

      __extends(TaskView, _super);

      function TaskView() {
        return TaskView.__super__.constructor.apply(this, arguments);
      }

      TaskView.prototype.tagName = 'tr';

      TaskView.prototype.template = '#task-template';

      return TaskView;

    })(Backbone.Marionette.ItemView);
    TasksView = (function(_super) {

      __extends(TasksView, _super);

      function TasksView() {
        return TasksView.__super__.constructor.apply(this, arguments);
      }

      TasksView.prototype.tagName = 'table';

      TasksView.prototype.id = 'tasksView';

      TasksView.prototype.itemView = TaskView;

      TasksView.prototype.appendHtml = function(collectionView, itemView) {
        return collectionView.$("tbody").append(itemView.el);
      };

      return TasksView;

    })(Backbone.Marionette.CollectionView);
    CheckView = (function(_super) {

      __extends(CheckView, _super);

      function CheckView() {
        return CheckView.__super__.constructor.apply(this, arguments);
      }

      CheckView.prototype.tagname = 'a';

      CheckView.prototype.initialize = function() {
        return this.template = _.template($('#check-template').html());
      };

      return CheckView;

    })(Backbone.Marionette.ItemView);
    NavBarView = (function(_super) {

      __extends(NavBarView, _super);

      function NavBarView() {
        return NavBarView.__super__.constructor.apply(this, arguments);
      }

      NavBarView.prototype.template = require('text!templates/navbar.html');

      NavBarView.prototype.initialize = function() {
        app.vent.on('scroll:window', this.addDropShadow, this);
        return this.model.bind('change', this.render, this);
      };

      NavBarView.prototype.render = function() {
        this.$el.html(_.template(this.template, this.model.toJSON()));
        return this;
      };

      NavBarView.prototype.serializeData = function() {
        return {
          name: this.model.get('name')
        };
      };

      NavBarView.prototype.addDropShadow = function() {
        if (window.pageYOffset > 0) {
          return this.$el.children().addClass('nav-drop-shadow');
        } else {
          return this.$el.children().removeClass('nav-drop-shadow');
        }
      };

      return NavBarView;

    })(Backbone.Marionette.Layout);
    App = (function(_super) {

      __extends(App, _super);

      function App() {
        return App.__super__.constructor.apply(this, arguments);
      }

      App.prototype.initialize = function() {
        var _this = this;
        this.user = new User;
        this.showApp();
        if (this.user.isSignedIn()) {
          this.showTasks();
        } else {
          this.showLogin();
        }
        return $(window).bind('scroll touchmove', function() {
          return _this.vent.trigger('scroll:window');
        });
      };

      App.prototype.showApp = function() {
        this.addRegions({
          main: 'body'
        });
        this.main.show(this.layout = new AppLayout);
        return this.layout.navigation.show(this.navigation = new NavBarView({
          model: this.user
        }));
      };

      App.prototype.showTasks = function() {
        this.user.fetch();
        this.layout.body.show(this.tasksView = new TasksView({
          model: this.tasks = new Tasks
        }));
        return this.tasks.fetch();
      };

      App.prototype.showLogin = function() {};

      return App;

    })(Backbone.Marionette.Application);
    initialize = function() {
      _.templateSettings = {
        evaluate: /\{\[([\s\S]+?)\]\}/g,
        interpolate: /\{\{([\s\S]+?)\}\}/g
      };
      window.app = new App;
      return window.app.initialize();
    };
    return {
      initialize: initialize
    };
  });

}).call(this);
