// Generated by CoffeeScript 1.3.3
(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $(function() {
    var $button, $select, addDropShadow, colorArray, decrementHeight, incrementHeight, name, renderColors, renderHeight, timezone;
    $(document).on(function() {
      'click';

      'a[href]:not(.delete, .delete-confirm, .target, .title)';
      return function(event) {
        event.preventDefault();
        return window.location = $(this).attr("href");
      };
    });
    $(document).on(function() {
      'tap';

      'a[href]:not(.delete, .delete-confirm, .target, .title)';
      return function(event) {
        event.preventDefault();
        return window.location = $(this).attr("href");
      };
    });
    if (__indexOf.call(window, 'ontouchend') >= 0) {
      $(document).delegate('body', 'click', function(e) {
        return $(e.target).trigger(function() {
          return 'tap';
        });
      });
    }
    window.onscroll = addDropShadow;
    window.addEventListener('touchmove', addDropShadow, false);
    addDropShadow = function() {
      var header;
      header = $('.navbar');
      if (window.pageYOffset > 0) {
        return header.addClass('nav-drop-shadow');
      } else {
        return header.removeClass('nav-drop-shadow');
      }
    };
    $select = $('select#timezone');
    if ($select.data("zone") !== null) {
      $select.val($select.data("zone"));
    }
    $('input#name').keyup(function() {
      if ($(this).val().length > 1) {
        if (!$(this).parents('.control-group').hasClass('success')) {
          return $(this).parents('.control-group').toggleClass("success");
        }
      } else {
        if ($(this).parents('.control-group').hasClass('success')) {
          return $(this).parents('.control-group').toggleClass("success");
        }
      }
    });
    $('input#email').keyup(function() {
      var filter;
      filter = /(.+)@(.+){2,}\.(.+){2,}/;
      if (filter.test($(this).val())) {
        if (!$(this).parents('.control-group').hasClass('success')) {
          return $(this).parents('.control-group').toggleClass("success");
        }
      } else {
        if ($(this).parents('.control-group').hasClass('success')) {
          return $(this).parents('.control-group').toggleClass("success");
        }
      }
    });
    $('input#password').keyup(function() {
      if ($(this).val().length >= 8) {
        if (!$(this).parents('.control-group').hasClass('success')) {
          return $(this).parents('.control-group').toggleClass("success");
        }
      } else {
        if ($(this).parents('.control-group').hasClass('success')) {
          return $(this).parents('.control-group').toggleClass("success");
        }
      }
    });
    if ($('div.btn-group[data-toggle-name=*]').length) {
      $('div.btn-group[data-toggle-name=*]').each(function() {
        var form, group, hidden, name;
        group = $(this);
        form = group.parents('form').eq(0);
        name = group.attr('data-toggle-name');
        hidden = $('input[name="' + name + '"]', form);
        return $('button', group).each(function() {
          var button;
          button = $(this);
          button.live('click', function() {
            return hidden.val($(this).val());
          });
          if (button.val() === hidden.val()) {
            return button.addClass('active');
          }
        });
      });
    }
    $('select[name="timezone"]').change(function(event) {
      var $button;
      $button = $('button.geolocate');
      if ($button.length) {
        return $button.css('color', '#333333');
      }
    });
    if (navigator.geolocation) {
      $('select[name="timezone"]').parent().append('<button class="btn geolocate" type="button"><i class="icon-map-marker"></i></button>');
      $button = $('button.geolocate');
      $('button.geolocate').click(function() {
        return navigator.geolocation.getCurrentPosition(function() {
          var lat, long, url, urlbase, username;
          lat = position.coords.latitude;
          long = position.coords.longitude;
          urlbase = "http://api.geonames.org/timezoneJSON?";
          username = "interstateone";
          url = urlbase + "lat=" + lat + "&" + "lng=" + long + "&" + "username=" + username;
          return $.get(url, function(data) {
            $button.css('color', 'green');
            return $('select[name="timezone"]').val(data.timezoneId);
          }).error(function() {
            return $button.css('color', 'red');
          });
        }, function(error) {
          switch (error.code) {
            case error.TIMEOUT:
              return alert('Timeout');
            case error.POSITION_UNAVAILABLE:
              return alert('Position unavailable');
            case error.PERMISSION_DENIED:
              return alert('Permission denied');
            case error.UNKNOWN_ERROR:
              return alert('Unknown error');
          }
        });
      });
    }
    jQuery.fn.reset = function() {
      return $(this).each(function() {
        return this.reset();
      });
    };
    $('a.add').click(function(e) {
      if (!$(this).children("i").hasClass("cancel")) {
        $("input#title").focus();
        $(this).children("i").animate({
          transform: 'rotate(45deg)'
        }, 'fast').toggleClass("cancel");
        $(this).css('color', "red");
        return $(this).siblings('#newtask').animate({
          opacity: 1
        }, 'fast').css("visibility", "visible");
      } else {
        $(this).children("i").animate({
          transform: ''
        }, 'fast').toggleClass("cancel");
        $(this).css('color', "#CCC");
        return $(this).siblings('#newtask').animate({
          opacity: 0
        }, 'fast', function() {
          $(this).css("visibility", "hidden");
          return $(this).reset();
        });
      }
    });
    $('#newtask > input#purpose').keypress(function(e) {
      if (e.which === 13) {
        e.preventDefault();
        $('#newtask').submit();
        return _gaq.push(['_trackEvent', 'task', 'create']);
      }
    });
    colorArray = function(numberOfRows, lightness) {
      var alpha, color, colors, hue, i, saturation, _i;
      colors = [];
      for (i = _i = 0; 0 <= numberOfRows ? _i <= numberOfRows : _i >= numberOfRows; i = 0 <= numberOfRows ? ++_i : --_i) {
        hue = i * 340 / (numberOfRows + 2);
        saturation = 0.8;
        alpha = 1.0;
        color = $.Color({
          hue: hue,
          saturation: saturation,
          lightness: lightness,
          alpha: alpha
        }).toHslaString();
        colors.push($.Color(color).toHexString());
      }
      return colors;
    };
    renderColors = function() {
      var barColors, bgColors, rows;
      rows = $('tbody').children();
      bgColors = colorArray(rows.size(), 0.8);
      barColors = colorArray(rows.size(), 0.6);
      return $(rows).each(function(row) {
        var $ministat;
        $ministat = $(this).children('td.title').children('.ministat');
        $ministat.css("background-color", bgColors[row]);
        return $ministat.children('.minibar').css("background-color", barColors[row]);
      });
    };
    renderColors();
    renderHeight = function() {
      var rows;
      rows = $('tbody').children();
      return $(rows).each(function(i) {
        var $bar, count, data, total;
        $bar = $(this).children('td.title').children('.ministat').children('.minibar');
        data = $bar.data();
        count = data.count;
        total = data.total;
        return $bar.css("height", Math.min(50 * count / total, 50));
      });
    };
    if ($('td.title').length) {
      renderHeight();
    }
    incrementHeight = function(target) {
      var $bar, data;
      $bar = $(target).parents('tr').children('td.title').children('.ministat').children('.minibar');
      data = $bar.data();
      data.count += 1;
      return renderHeight();
    };
    decrementHeight = function(target) {
      var $bar, data;
      $bar = $(target).parents('tr').children('td.title').children('.ministat').children('.minibar');
      data = $bar.data();
      data.count -= 1;
      return renderHeight();
    };
    $('#newtask').submit(function(e) {
      e.preventDefault();
      return $.post("/new", $(this).serialize(), function(data) {
        $('tbody').append(data);
        $('.hero-unit').hide();
        renderColors();
        $('a.add').children('i').animate({
          transform: ''
        }, 'fast').toggleClass("cancel");
        return $('a.add').css('color', "#CCC").siblings('#newtask').animate({
          opacity: 0
        }, 'fast', function() {
          return $(this).reset();
        });
      }, "text");
    });
    $(document).on("click", 'a.delete', function(e) {
      return $(this).siblings(".deleteModal").modal();
    });
    $(document).on("click", 'a.delete-confirm', function(e) {
      var clicked;
      clicked = this;
      e.preventDefault();
      return $.post(clicked.href, {
        _method: 'delete'
      }, function(data) {
        $(this).parents(".deleteModal").modal('hide');
        return window.location.pathname = "/";
      }, "script");
    });
    $(document).on("click", ".delete-confirm", function() {
      return $('.delete-confirm').button('loading');
    });
    $(document).on("click", 'a.target', function(e) {
      var clicked;
      clicked = this;
      e.preventDefault();
      $(clicked).children('img').toggleClass("complete");
      if ($(clicked).children('img').hasClass("complete")) {
        incrementHeight(clicked);
        _gaq.push(['_trackEvent', 'check', 'complete']);
      } else {
        decrementHeight(clicked);
        _gaq.push(['_trackEvent', 'check', 'uncomplete']);
      }
      return $.post(clicked.href, null, function(data) {
        if (data !== '') {
          $(clicked).children('img').toggleClass("complete");
          if ($(clicked).children('img').hasClass("complete")) {
            return incrementHeight(clicked);
          } else {
            return decrementHeight(clicked);
          }
        }
      }).error(function() {
        return $(clicked).children('img').toggleClass("complete");
      });
    });
    $('button.forgot').click(function(e) {
      e.preventDefault();
      $(this).parents('form').attr("action", '/forgot');
      return $(this).parents('form').submit();
    });
    timezone = jstz.determine_timezone();
    name = timezone.name();
    return $('input#timezone').val(name);
  });

}).call(this);
