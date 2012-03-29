$(document).ready(function() {

	// Prevent iOS from opening a new Safari instance for anchor tags
	// :not selector prevents operating on classes that are listed below
	$(document).on('click', 'a[href]:not(.delete, .delete-confirm, .target, .title)', function (event) {
		event.preventDefault();
		window.location = $(this).attr("href");
	});

	// Password length validator
	$('input#password').keyup(function () {
		if ($(this).val().length >= 8) {
			if ($(this).siblings('span.valid').length === 0) {
				$(this).parent().append("<span class='help-inline valid'><i class='icon-ok'></i></span>");
			}
		} else {
			$(this).siblings('span.valid').remove();
		}
	});

	// Email format validator
	$('input#email').keyup(function () {
		var filter = /^(([a-zA-Z0-9_.-])+@([a-zA-Z0-9_.-])+\.([a-zA-Z])+([a-zA-Z])+)?$/;
		if (filter.test($(this).val())) {
			if ($(this).siblings('span.valid').length === 0) {
				$(this).parent().append("<span class='help-inline valid'><i class='icon-ok'></i></span>");
			}
		} else {
			$(this).siblings('span.valid').remove();
		}
	});

	// Post a new task
	$('#newtask').submit(function() {
		$.post("/", $(this).serialize(), function(data){
			$('tbody').append(data).children("tr").each( function (i, obj) {
				obj = $(obj).children("td.title").children("span.title");
				makeEditable(obj);
				console.log(obj);
			});
			$('#newtask').each(function(){this.reset();});
		}, "text");
		return false;
	});

	// Submit a new task with the enter key
	$('#newtask .input').keypress(function(e){
		if(e.which === 13){
			e.preventDefault();
			$('form#login').submit();
			return false;
		}
	});

	// Delete a task
	$(document).on("click", 'a.delete', function(e) {
		$(this).siblings(".deleteModal").modal();
	});

	// Delete a task
	$(document).on("click", 'a.delete-confirm', function(e) {
		var clicked = this;
		e.preventDefault();
		$.post(clicked.href, { _method: 'delete' }, function(data) {
			if (window.location.pathname == "/edit") {
				$(clicked).closest('tr').remove();
			} else {
				window.location.pathname = "/edit";
			}
		}, "script");
	});

	// Complete a task
	$(document).on("click", 'a.target', function(e) {
		var clicked = this;
		e.preventDefault();
		$.post(clicked.href, null, function() {
			$(clicked).children('img').toggleClass("complete");
		});
	});

	$('button.forgot').click(function(e) {
		e.preventDefault();
	});

	var editable = false;

	// Rename a task with the enter key by blurring the input
	$(document).on("keypress", 'span.title', function(e){
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
			$(this).parent().siblings("td").children("span.title").trigger("editableSubmit");
			editable = false;
		} else {
			$(this).parent().siblings("td").children("span.title").trigger("blur");
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
					$.post($(this).closest("span.title").attr("href"), {"title": content.current}, function(data) {
						if (data !== "true") {
							$("body > .container").prepend(data).alert()
							$(this).text(content.previous);
						}
					});
				}
			}
		});
	};

	makeEditable($("span.title"));
});

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