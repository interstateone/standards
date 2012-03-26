$(document).ready(function() {

	// Prevent iOS from opening a new Safari instance for anchor tags
	// :not selector prevents operating on classes that are listed below
	$('a[href]:not(.delete, .delete-confirm, .target)').live('click', function (event) {
		event.preventDefault();
		console.log("Test");
	    window.location = $(this).attr("href");
	});

	// Post a new task
	$('#newtask').submit(function() {
		$.post("/", $(this).serialize(), function(data){
			$('tbody').append(data);
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
	$('a.delete').live("click", function(e) {
		$(this).siblings(".deleteModal").modal();
	});

	// Delete a task
	$('a.delete-confirm').live("click", function(e) {
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
	$('a.target').live("click", function(e) {
		var clicked = this;
		e.preventDefault();
		$.post(clicked.href, null, function() {
			$(clicked).children('img').toggleClass("complete");
		});
	});

	$('button.forgot').click(function(e) {
		e.preventDefault();
		$("form").attr("action", "/forgot").submit();
	});
});