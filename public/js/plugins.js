$(document).ready(function() {

	// Prevent iOS from opening a new Safari instance for anchor tags
	// :not selector prevents operating on classes that are listed below
	$(document).on('click', 'a[href]:not(.delete, .delete-confirm, .target, .title)', function (event) {
		event.preventDefault();
		window.location = $(this).attr("href");
	});

	$(document).on('tap', 'a[href]:not(.delete, .delete-confirm, .target, .title)', function (event) {
		event.preventDefault();
		window.location = $(this).attr("href");
	});

	// Subsitutes tap events for click events in supported browsers
	if ('ontouchend' in window) {
		$(document).delegate('body', 'click', function(e) {
			$(e.target).trigger('tap');
		});
	}

	// Add drop shadow to navbar when page is scrolled
	window.onscroll = addDropShadow;
	// Use the touchmove event for touch devices because onscroll isn't fired until the scrolling/panning stops
	window.addEventListener('touchmove', addDropShadow, false);

	function addDropShadow () {
		var header = $('.navbar');
		if (window.pageYOffset > 0) {
			header.addClass('nav-drop-shadow');
		} else {
			header.removeClass('nav-drop-shadow');
		}
	}

	// Set the timezone dropdown to the current value
	var $select = $('select#timezone');
	if ($select.data("zone") !== null) {
		$select.val($select.data("zone"));
	}

	// Name validator
	// Must be longer than one character
	$('input#name').keyup(function () {
		if ($(this).val().length > 1) {
			if (!$(this).parents('.control-group').hasClass('success')) {
				$(this).parents('.control-group').toggleClass("success");
			}
		} else {
			if ($(this).parents('.control-group').hasClass('success')) {
				$(this).parents('.control-group').toggleClass("success");
			}
		}
	});

	// Email format validator
	// at least one character followed by '@' followed by at least two characters, '.', at least two characters
	$('input#email').keyup(function () {
		var filter = /(.+)@(.+){2,}\.(.+){2,}/;
		if (filter.test($(this).val())) {
			if (!$(this).parents('.control-group').hasClass('success')) {
				$(this).parents('.control-group').toggleClass("success");
			}
		} else {
			if ($(this).parents('.control-group').hasClass('success')) {
				$(this).parents('.control-group').toggleClass("success");
			}
		}
	});

	// Password length validator
	// Must be at least 8 characters long
	$('input#password').keyup(function () {
		if ($(this).val().length >= 8) {
			if (!$(this).parents('.control-group').hasClass('success')) {
				$(this).parents('.control-group').toggleClass("success");
			}
		} else {
			if ($(this).parents('.control-group').hasClass('success')) {
				$(this).parents('.control-group').toggleClass("success");
			}
		}
	});

	// If this is the settings page, handle the weekday radio buttons
	if($('div.btn-group[data-toggle-name=*]').length) {
		$('div.btn-group[data-toggle-name=*]').each(function(){
			var group   = $(this);
			var form    = group.parents('form').eq(0);
			var name    = group.attr('data-toggle-name');
			var hidden  = $('input[name="' + name + '"]', form);
			$('button', group).each(function(){
				var button = $(this);
				button.live('click', function(){
					hidden.val($(this).val());
				});
				if(button.val() == hidden.val()) {
					button.addClass('active');
				}
			});
		});
	}

	// Map JS reset() function to jQuery
	jQuery.fn.reset = function () {
		$(this).each (function() { this.reset(); });
	};

	// Show new task form when user clicks the plus button
	$('a.add').click( function (e) {
		if (!$(this).children("i").hasClass("cancel")) {
			$("input#title").focus();
			$(this).children("i").animate({transform: 'rotate(45deg)'}, 'fast').toggleClass("cancel");
			$(this).css('color', "red");
			$(this).siblings('#newtask').animate({opacity: 1}, 'fast').css("visibility", "visible");
		} else {
			$(this).children("i").animate({transform: ''}, 'fast').toggleClass("cancel");
			$(this).css('color', "#CCC");
			$(this).siblings('#newtask').animate({opacity: 0}, 'fast', function() {
				$(this).css("visibility", "hidden");
				$(this).reset();
			});
		}
	});

	// Submit a new task with the enter key
	$('#newtask > input#purpose').keypress(function(e){
		if(e.which === 13){
			e.preventDefault();
			$('#newtask').submit();
			_gaq.push(['_trackEvent', 'task', 'create']);
		}
	});

	function colorArray (numberOfRows, lightness) {
		colors = [];
		var hue, saturation, alpha;
		for (var i = 0; i < numberOfRows; i++) {
			hue = i * 340 / (numberOfRows + 2);
			saturation = 0.8;
			// lightness = 0.5;
			alpha = 1.0;
			var color = $.Color({hue: hue, saturation: saturation, lightness: lightness, alpha: alpha}).toHslaString();
			colors.push($.Color(color).toHexString());
		}
		return colors;
	}

	var renderColors = function () {
		var rows = $('tbody').children();
		bgColors = colorArray(rows.size(), 0.8);
		barColors = colorArray(rows.size(), 0.6);
		$(rows).each( function (i) {
			var $ministat = $(this).children('td.title').children('.ministat');
			$ministat.css("background-color", bgColors[i]);
			$ministat.children('.minibar').css("background-color", colors[i]);
		});
	};
	renderColors();

	var renderHeight = function () {
		var rows = $('tbody').children();
		$(rows).each( function (i) {
			var $bar = $(this).children('td.title').children('.ministat').children('.minibar');
			var data = $bar.data();
			var count = data.count;
			var total = data.total;
			$bar.css("height", Math.min(50 * count / total, 50));
		});
	};

	// If this is the homepage, call renderHeight() once
	if ($('td.title').length) {
		renderHeight();
	}

	var incrementHeight = function (target) {
		var $bar = $(target).parents('tr').children('td.title').children('.ministat').children('.minibar');
		// Caching the data object is faster than calling it twice (http://api.jquery.com/data/)
		var data = $bar.data();
		data.count += 1;
		// Rerender the bar heights
		renderHeight();
	};

	var decrementHeight = function (target) {
		var $bar = $(target).parents('tr').children('td.title').children('.ministat').children('.minibar');
		// Caching the data object is faster than calling it twice (http://api.jquery.com/data/)
		var data = $bar.data();
		data.count -= 1;
		// Rerender the bar heights
		renderHeight();
	};

	// Post a new task
	$('#newtask').submit(function(e) {
		e.preventDefault();
		$.post("/new", $(this).serialize(), function(data){
			// Append the new task row
			$('tbody').append(data);

			// Remove welcome message after submitting first task
			$('.hero-unit').hide();

			renderColors();
			$('a.add').children('i').animate({transform: ''}, 'fast').toggleClass("cancel");
			$('a.add').css('color', "#CCC")
					.siblings('#newtask')
					.animate({opacity: 0}, 'fast', function() {
						$(this).reset();
					});
		}, "text");
	});

	// Delete a task modal
	$(document).on("click", 'a.delete', function(e) {
		$(this).siblings(".deleteModal").modal();
	});

	// Delete a task
	$(document).on("click", 'a.delete-confirm', function(e) {
		var clicked = this;
		e.preventDefault();
		$.post(clicked.href, { _method: 'delete' }, function(data) {
				$(this).parents(".deleteModal").modal('hide');
				window.location.pathname = "/";
		}, "script");
	});

	// Set the delete button in the delete task modal to be stateful
	$(document).on("click", ".delete-confirm", function() {
		$('.delete-confirm').button('loading');
	});

	// Check a task
	$(document).on("click", 'a.target', function(e) {
		var clicked = this;
		e.preventDefault();
		$(clicked).children('img').toggleClass("complete");
		if ($(clicked).children('img').hasClass("complete")) {
			incrementHeight(clicked);
			_gaq.push(['_trackEvent', 'check', 'complete']);
		} else {
			decrementHeight(clicked);
			_gaq.push(['_trackEvent', 'check', 'uncomplete']);
		}
		$.post(clicked.href, null, function(data) {
			if (data !== '') {
				$(clicked).children('img').toggleClass("complete");
				if ($(clicked).children('img').hasClass("complete")) {
					incrementHeight(clicked);
				} else {
					decrementHeight(clicked);
				}
			}
		}).error( function() {
			$(clicked).children('img').toggleClass("complete");
		});
	});

	// Let forgot password button make post to alternate route than submitting the login
	$('button.forgot').click(function(e) {
		e.preventDefault();
		$(this).parents('form').attr("action", '/forgot');
		$(this).parents('form').submit();
	});

	var editable = false;

	// Rename a task with the enter key by blurring the input
	$(document).on("keypress", 'p > span.title', function(e){
		if(e.which === 13){
			e.preventDefault();
			if (editable) {
				$(this).trigger("editableSubmit");
				editable = false;
			}
		}
	});

	// Let the edit button make the title editable
	$(document).on("click", "a.rename", function (e) {
		if (editable) {
			$(this).parent().siblings("td").children("p > span.title").trigger("editableSubmit");
			editable = false;
		} else {
			$(this).parent().siblings("td").children("p > span.title").trigger("blur");
			editable = true;
		}
		// console.log($(this).parent().siblings("td").children("span.title"));
	});

	// Make titles editable and set submit callback to post the new title and catch errors
	var makeEditable = function (obj) {
		$(obj).editable({
			editBy: "blur",
			submitBy: "editableSubmit",
			onSubmit: function (content) {
				if (content.current !== content.previous) {
					$.post($(this).closest("p > span.title").attr("href"), {"title": content.current}, function(data) {
						if (data !== "true") {
							$("body > .container").prepend(data).alert();
							$(this).text(content.previous);
						}
					});
				}
			}
		});
	};

	makeEditable($("p > span.title"));

	// Submit timezone with signup
	var timezone = jstz.determine_timezone();
	var name = timezone.name();
	$('input#timezone').val(name);
});

// ####################################################################################
//
//  Plugins
//
// ####################################################################################

(function($){
/*
 * Editable 1.3.3
 *
 * Copyright (c) 2009 Arash Karimzadeh (arashkarimzadeh.com)
 * Licensed under the MIT (MIT-LICENSE.txt)
 * http://www.opensource.org/licenses/mit-license.php
 *
 * Date: Mar 02 2009
 */
$.fn.editable = function(options){
	var defaults = {
		onEdit: null,
		onSubmit: null,
		onCancel: null,
		editClass: null,
		submit: null,
		cancel: null,
		type: 'text', //text, textarea or select
		submitBy: 'blur', //blur,change,dblclick,click
		editBy: 'click',
		options: null
	};
	if(options=='disable')
		return this.unbind(this.data('editable.options').editBy,this.data('editable.options').toEditable);
	if(options=='enable')
		return this.bind(this.data('editable.options').editBy,this.data('editable.options').toEditable);
	if(options=='destroy')
		return  this.unbind(this.data('editable.options').editBy,this.data('editable.options').toEditable)
					.data('editable.previous',null)
					.data('editable.current',null)
					.data('editable.options',null);

	var options = $.extend(defaults, options);

	options.toEditable = function(){
		$this = $(this);
		$this.data('editable.current',$this.html());
		opts = $this.data('editable.options');
		$.editableFactory[opts.type].toEditable($this.empty(),opts);
		// Configure events,styles for changed content
		$this.data('editable.previous',$this.data('editable.current'))
			 .children()
				 .focus()
				 .addClass(opts.editClass);
		// Submit Event
		if(opts.submit){
			$('<button/>').appendTo($this)
						.html(opts.submit)
						.one('mouseup',function(){opts.toNonEditable($(this).parent(),true)});
		}else
			$this.one(opts.submitBy,function(){opts.toNonEditable($(this),true)})
				 .children()
				 	.one(opts.submitBy,function(){opts.toNonEditable($(this).parent(),true)});
		// Cancel Event
		if(opts.cancel)
			$('<button/>').appendTo($this)
						.html(opts.cancel)
						.one('mouseup',function(){opts.toNonEditable($(this).parent(),false)});
		// Call User Function
		if($.isFunction(opts.onEdit))
			opts.onEdit.apply(	$this,
									[{
										current:$this.data('editable.current'),
										previous:$this.data('editable.previous')
									}]
								);
	}
	options.toNonEditable = function($this,change){
		opts = $this.data('editable.options');
		// Configure events,styles for changed content
		$this.one(opts.editBy,opts.toEditable)
			 .data( 'editable.current',
				    change
						?$.editableFactory[opts.type].getValue($this,opts)
						:$this.data('editable.current')
					)
			 .html(
				    opts.type=='password'
				   		?'*****'
						:$this.data('editable.current')
					);
		// Call User Function
		var func = null;
		if($.isFunction(opts.onSubmit)&&change==true)
			func = opts.onSubmit;
		else if($.isFunction(opts.onCancel)&&change==false)
			func = opts.onCancel;
		if(func!=null)
			func.apply($this,
						[{
							current:$this.data('editable.current'),
							previous:$this.data('editable.previous')
						}]
					);
	}
	this.data('editable.options',options);
	return  this.one(options.editBy,options.toEditable);
}
$.editableFactory = {
	'text': {
		toEditable: function($this,options){
			$('<input/>').appendTo($this)
						 .val($this.data('editable.current'));
		},
		getValue: function($this,options){
			return $this.children().val();
		}
	},
	'password': {
		toEditable: function($this,options){
			$this.data('editable.current',$this.data('editable.password'));
			$this.data('editable.previous',$this.data('editable.password'));
			$('<input type="password"/>').appendTo($this)
										 .val($this.data('editable.current'));
		},
		getValue: function($this,options){
			$this.data('editable.password',$this.children().val());
			return $this.children().val();
		}
	},
	'textarea': {
		toEditable: function($this,options){
			$('<textarea/>').appendTo($this)
							.val($this.data('editable.current'));
		},
		getValue: function($this,options){
			return $this.children().val();
		}
	},
	'select': {
		toEditable: function($this,options){
			$select = $('<select/>').appendTo($this);
			$.each( options.options,
					function(key,value){
						$('<option/>').appendTo($select)
									.html(value)
									.attr('value',key);
					}
				   )
			$select.children().each(
				function(){
					var opt = $(this);
					if(opt.text()==$this.data('editable.current'))
						return opt.attr('selected', 'selected').text();
				}
			)
		},
		getValue: function($this,options){
			var item = null;
			$('select', $this).children().each(
				function(){
					if($(this).attr('selected'))
						return item = $(this).text();
				}
			)
			return item;
		}
	}
}
})(jQuery);

/* 
 * Original script by Josh Fraser (http://www.onlineaspect.com)
 * Continued and maintained by Jon Nylander at https://bitbucket.org/pellepim/jstimezonedetect
 *
 * Provided under the Do Whatever You Want With This Code License.
 */

/**
 * Namespace to hold all the code for timezone detection.
 */
var jstz = (function () {
    'use strict';
    var HEMISPHERE_SOUTH = 's',
        
        /** 
         * Gets the offset in minutes from UTC for a certain date.
         * @param {Date} date
         * @returns {Number}
         */
        get_date_offset = function (date) {
            var offset = -date.getTimezoneOffset();
            return (offset !== null ? offset : 0);
        },
        
        get_january_offset = function () {
            return get_date_offset(new Date(2010, 0, 1, 0, 0, 0, 0));
        },
    
        get_june_offset = function () {
            return get_date_offset(new Date(2010, 5, 1, 0, 0, 0, 0));
        },
        
        /**
         * Private method.
         * Checks whether a given date is in daylight savings time.
         * If the date supplied is after june, we assume that we're checking
         * for southern hemisphere DST.
         * @param {Date} date
         * @returns {Boolean}
         */
        date_is_dst = function (date) {
            var base_offset = ((date.getMonth() > 5 ? get_june_offset() 
                                                : get_january_offset())),
                date_offset = get_date_offset(date); 
            
            return (base_offset - date_offset) !== 0;
        },
    
        /**
         * This function does some basic calculations to create information about 
         * the user's timezone.
         * 
         * Returns a key that can be used to do lookups in jstz.olson.timezones.
         * 
         * @returns {String}  
         */
        
        lookup_key = function () {
            var january_offset = get_january_offset(), 
                june_offset = get_june_offset(), 
                diff = get_january_offset() - get_june_offset();
                
            if (diff < 0) {
                return january_offset + ",1";
            } else if (diff > 0) {
                return june_offset + ",1," + HEMISPHERE_SOUTH;
            }
            
            return january_offset + ",0";
        },
    
        /**
         * Uses get_timezone_info() to formulate a key to use in the olson.timezones dictionary.
         * 
         * Returns a primitive object on the format:
         * {'timezone': TimeZone, 'key' : 'the key used to find the TimeZone object'}
         * 
         * @returns Object 
         */
        determine_timezone = function () {
            var key = lookup_key();
            return new jstz.TimeZone(jstz.olson.timezones[key]);
        };
    
    return {
        determine_timezone : determine_timezone,
        date_is_dst : date_is_dst
    };
}());

/**
 * A simple object containing information of utc_offset, which olson timezone key to use, 
 * and if the timezone cares about daylight savings or not.
 * 
 * @constructor
 * @param {string} offset - for example '-11:00'
 * @param {string} olson_tz - the olson Identifier, such as "America/Denver"
 * @param {boolean} uses_dst - flag for whether the time zone somehow cares about daylight savings.
 */
jstz.TimeZone = (function () {
    'use strict';    
    var timezone_name = null,
        uses_dst = null,
        utc_offset = null,
        
        name = function () {
            return timezone_name;
        },
        
        dst = function () {
            return uses_dst;
        },
        
        offset = function () {
            return utc_offset;
        },
        
        /**
         * Checks if a timezone has possible ambiguities. I.e timezones that are similar.
         * 
         * If the preliminary scan determines that we're in America/Denver. We double check
         * here that we're really there and not in America/Mazatlan.
         * 
         * This is done by checking known dates for when daylight savings start for different
         * timezones.
         */
        ambiguity_check = function () {
            var ambiguity_list = jstz.olson.ambiguity_list[timezone_name],
                length = ambiguity_list.length, 
                i = 0,
                tz = ambiguity_list[0];
            
            for (; i < length; i += 1) {
                tz = ambiguity_list[i];
        
                if (jstz.date_is_dst(jstz.olson.dst_start_dates[tz])) {
                    timezone_name = tz;
                    return;
                }   
            }
        },
        
        /**
         * Checks if it is possible that the timezone is ambiguous.
         */
        is_ambiguous = function () {
            return typeof (jstz.olson.ambiguity_list[timezone_name]) !== 'undefined';
        },
        
        /**
        * Constructor for jstz.TimeZone
        */
        Constr = function (tz_info) {
            utc_offset = tz_info[0];
            timezone_name = tz_info[1];
            uses_dst = tz_info[2];
            if (is_ambiguous()) {
                ambiguity_check();
            }
        };
    
    /**
     * Public API for jstz.TimeZone
     */
    Constr.prototype = {
        constructor : jstz.TimeZone,
        name : name,
        dst : dst,
        offset : offset
    };
    
    return Constr;
}());

jstz.olson = {};

/*
 * The keys in this dictionary are comma separated as such:
 * 
 * First the offset compared to UTC time in minutes.
 *  
 * Then a flag which is 0 if the timezone does not take daylight savings into account and 1 if it 
 * does.
 * 
 * Thirdly an optional 's' signifies that the timezone is in the southern hemisphere, 
 * only interesting for timezones with DST.
 * 
 * The mapped arrays is used for constructing the jstz.TimeZone object from within 
 * jstz.determine_timezone();
 */
jstz.olson.timezones = (function () {
    "use strict";
    return {
        '-720,0'   : ['-12:00', 'Etc/GMT+12', false],
        '-660,0'   : ['-11:00', 'Pacific/Pago_Pago', false],
        '-600,1'   : ['-11:00', 'America/Adak', true],
        '-600,0'   : ['-10:00', 'Pacific/Honolulu', false],
        '-570,0'   : ['-09:30', 'Pacific/Marquesas', false],
        '-540,0'   : ['-09:00', 'Pacific/Gambier', false],
        '-540,1'   : ['-09:00', 'America/Anchorage', true],
        '-480,1'   : ['-08:00', 'America/Los_Angeles', true],
        '-480,0'   : ['-08:00', 'Pacific/Pitcairn', false],
        '-420,0'   : ['-07:00', 'America/Phoenix', false],
        '-420,1'   : ['-07:00', 'America/Denver', true],
        '-360,0'   : ['-06:00', 'America/Guatemala', false],
        '-360,1'   : ['-06:00', 'America/Chicago', true],
        '-360,1,s' : ['-06:00', 'Pacific/Easter', true],
        '-300,0'   : ['-05:00', 'America/Bogota', false],
        '-300,1'   : ['-05:00', 'America/New_York', true],
        '-270,0'   : ['-04:30', 'America/Caracas', false],
        '-240,1'   : ['-04:00', 'America/Halifax', true],
        '-240,0'   : ['-04:00', 'America/Santo_Domingo', false],
        '-240,1,s' : ['-04:00', 'America/Asuncion', true],
        '-210,1'   : ['-03:30', 'America/St_Johns', true],
        '-180,1'   : ['-03:00', 'America/Godthab', true],
        '-180,0'   : ['-03:00', 'America/Argentina/Buenos_Aires', false],
        '-180,1,s' : ['-03:00', 'America/Montevideo', true],
        '-120,0'   : ['-02:00', 'America/Noronha', false],
        '-120,1'   : ['-02:00', 'Etc/GMT+2', true],
        '-60,1'    : ['-01:00', 'Atlantic/Azores', true],
        '-60,0'    : ['-01:00', 'Atlantic/Cape_Verde', false],
        '0,0'      : ['00:00', 'Etc/UTC', false],
        '0,1'      : ['00:00', 'Europe/London', true],
        '60,1'     : ['+01:00', 'Europe/Berlin', true],
        '60,0'     : ['+01:00', 'Africa/Lagos', false],
        '60,1,s'   : ['+01:00', 'Africa/Windhoek', true],
        '120,1'    : ['+02:00', 'Asia/Beirut', true],
        '120,0'    : ['+02:00', 'Africa/Johannesburg', false],
        '180,1'    : ['+03:00', 'Europe/Moscow', true],
        '180,0'    : ['+03:00', 'Asia/Baghdad', false],
        '210,1'    : ['+03:30', 'Asia/Tehran', true],
        '240,0'    : ['+04:00', 'Asia/Dubai', false],
        '240,1'    : ['+04:00', 'Asia/Yerevan', true],
        '270,0'    : ['+04:30', 'Asia/Kabul', false],
        '300,1'    : ['+05:00', 'Asia/Yekaterinburg', true],
        '300,0'    : ['+05:00', 'Asia/Karachi', false],
        '330,0'    : ['+05:30', 'Asia/Kolkata', false],
        '345,0'    : ['+05:45', 'Asia/Kathmandu', false],
        '360,0'    : ['+06:00', 'Asia/Dhaka', false],
        '360,1'    : ['+06:00', 'Asia/Omsk', true],
        '390,0'    : ['+06:30', 'Asia/Rangoon', false],
        '420,1'    : ['+07:00', 'Asia/Krasnoyarsk', true],
        '420,0'    : ['+07:00', 'Asia/Jakarta', false],
        '480,0'    : ['+08:00', 'Asia/Shanghai', false],
        '480,1'    : ['+08:00', 'Asia/Irkutsk', true],
        '525,0'    : ['+08:45', 'Australia/Eucla', true],
        '525,1,s'  : ['+08:45', 'Australia/Eucla', true],
        '540,1'    : ['+09:00', 'Asia/Yakutsk', true],
        '540,0'    : ['+09:00', 'Asia/Tokyo', false],
        '570,0'    : ['+09:30', 'Australia/Darwin', false],
        '570,1,s'  : ['+09:30', 'Australia/Adelaide', true],
        '600,0'    : ['+10:00', 'Australia/Brisbane', false],
        '600,1'    : ['+10:00', 'Asia/Vladivostok', true],
        '600,1,s'  : ['+10:00', 'Australia/Sydney', true],
        '630,1,s'  : ['+10:30', 'Australia/Lord_Howe', true],
        '660,1'    : ['+11:00', 'Asia/Kamchatka', true],
        '660,0'    : ['+11:00', 'Pacific/Noumea', false],
        '690,0'    : ['+11:30', 'Pacific/Norfolk', false],
        '720,1,s'  : ['+12:00', 'Pacific/Auckland', true],
        '720,0'    : ['+12:00', 'Pacific/Tarawa', false],
        '765,1,s'  : ['+12:45', 'Pacific/Chatham', true],
        '780,0'    : ['+13:00', 'Pacific/Tongatapu', false],
        '780,1,s'  : ['+13:00', 'Pacific/Apia', true],
        '840,0'    : ['+14:00', 'Pacific/Kiritimati', false]
    };
}());

/**
 * This object contains information on when daylight savings starts for
 * different timezones.
 * 
 * The list is short for a reason. Often we do not have to be very specific
 * to single out the correct timezone. But when we do, this list comes in
 * handy.
 * 
 * Each value is a date denoting when daylight savings starts for that timezone.
 */
jstz.olson.dst_start_dates = (function () {
    "use strict";
    return {
        'America/Denver' : new Date(2011, 2, 13, 3, 0, 0, 0),
        'America/Mazatlan' : new Date(2011, 3, 3, 3, 0, 0, 0),
        'America/Chicago' : new Date(2011, 2, 13, 3, 0, 0, 0),
        'America/Mexico_City' : new Date(2011, 3, 3, 3, 0, 0, 0),
        'Atlantic/Stanley' : new Date(2011, 8, 4, 7, 0, 0, 0),
        'America/Asuncion' : new Date(2011, 9, 2, 3, 0, 0, 0),
        'America/Santiago' : new Date(2011, 9, 9, 3, 0, 0, 0),
        'America/Campo_Grande' : new Date(2011, 9, 16, 5, 0, 0, 0),
        'America/Montevideo' : new Date(2011, 9, 2, 3, 0, 0, 0),
        'America/Sao_Paulo' : new Date(2011, 9, 16, 5, 0, 0, 0),
        'America/Los_Angeles' : new Date(2011, 2, 13, 8, 0, 0, 0),
        'America/Santa_Isabel' : new Date(2011, 3, 5, 8, 0, 0, 0),
        'America/Havana' : new Date(2011, 2, 13, 2, 0, 0, 0),
        'America/New_York' : new Date(2011, 2, 13, 7, 0, 0, 0),
        'Asia/Gaza' : new Date(2011, 2, 26, 23, 0, 0, 0),
        'Asia/Beirut' : new Date(2011, 2, 27, 1, 0, 0, 0),
        'Europe/Minsk' : new Date(2011, 2, 27, 2, 0, 0, 0),
        'Europe/Helsinki' : new Date(2011, 2, 27, 4, 0, 0, 0),
        'Europe/Istanbul' : new Date(2011, 2, 28, 5, 0, 0, 0),
        'Asia/Damascus' : new Date(2011, 3, 1, 2, 0, 0, 0),
        'Asia/Jerusalem' : new Date(2011, 3, 1, 6, 0, 0, 0),
        'Africa/Cairo' : new Date(2010, 3, 30, 4, 0, 0, 0),
        'Asia/Yerevan' : new Date(2011, 2, 27, 4, 0, 0, 0),
        'Asia/Baku'    : new Date(2011, 2, 27, 8, 0, 0, 0),
        'Pacific/Auckland' : new Date(2011, 8, 26, 7, 0, 0, 0),
        'Pacific/Fiji' : new Date(2010, 11, 29, 23, 0, 0, 0),
        'America/Halifax' : new Date(2011, 2, 13, 6, 0, 0, 0),
        'America/Goose_Bay' : new Date(2011, 2, 13, 2, 1, 0, 0),
        'America/Miquelon' : new Date(2011, 2, 13, 5, 0, 0, 0),
        'America/Godthab' : new Date(2011, 2, 27, 1, 0, 0, 0)
    };
}());

/**
 * The keys in this object are timezones that we know may be ambiguous after
 * a preliminary scan through the olson_tz object.
 * 
 * The array of timezones to compare must be in the order that daylight savings
 * starts for the regions.
 */
jstz.olson.ambiguity_list = {
    'America/Denver' : ['America/Denver', 'America/Mazatlan'],
    'America/Chicago' : ['America/Chicago', 'America/Mexico_City'],
    'America/Asuncion' : ['Atlantic/Stanley', 'America/Asuncion', 'America/Santiago', 'America/Campo_Grande'],
    'America/Montevideo' : ['America/Montevideo', 'America/Sao_Paulo'],
    'Asia/Beirut' : ['Asia/Gaza', 'Asia/Beirut', 'Europe/Minsk', 'Europe/Helsinki', 'Europe/Istanbul', 'Asia/Damascus', 'Asia/Jerusalem', 'Africa/Cairo'],
    'Asia/Yerevan' : ['Asia/Yerevan', 'Asia/Baku'],
    'Pacific/Auckland' : ['Pacific/Auckland', 'Pacific/Fiji'],
    'America/Los_Angeles' : ['America/Los_Angeles', 'America/Santa_Isabel'],
    'America/New_York' : ['America/Havana', 'America/New_York'],
    'America/Halifax' : ['America/Goose_Bay', 'America/Halifax'],
    'America/Godthab' : ['America/Miquelon', 'America/Godthab']
};