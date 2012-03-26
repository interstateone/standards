$(document).ready(function() {

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
		var clicked = this;
		e.preventDefault();
		$.post(clicked.href, { _method: 'delete' }, function(data) {
			$(clicked).closest('tr').remove();
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

	// View a task
	$('a.view').live("click", function(e) {
		var clicked = this;
	});

	// Prevent iOS from opening a new Safari instance
	$('a[href]').live('click', function (event) {
		event.preventDefault();
	    window.location = $(this).attr("href");
	});
});