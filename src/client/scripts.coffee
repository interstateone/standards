$ ->

	# Prevent iOS from opening a new Safari instance for anchor tags unless pointing to external page
	$(document).on 'click tap', 'a[href]', (event) ->
		unless ~$(event.target).attr('href').indexOf('http:')
			event.preventDefault()
			window.location = $(event.target).attr('href')

	# Let forgot password button make post to alternate route than submitting the login
	$('button.forgot').click (e) ->
		e.preventDefault()
		$(this).parents('form').attr("action", '/forgot')
		$(this).parents('form').submit()

	# Add drop shadow to navbar when page is scrolled
	$(window).on 'scroll touchmove', ->
		if window.pageYOffset > 0 then $('.navbar').addClass 'nav-drop-shadow'
		else $('.navbar').removeClass 'nav-drop-shadow'

	# Name validator
	# Must be longer than one character
	$('input#name').keyup ->
		if $(this).val().length > 1
			if !$(this).parents('.control-group').hasClass('success')
				$(this).parents('.control-group').toggleClass("success")
		else
			if $(this).parents('.control-group').hasClass('success')
				$(this).parents('.control-group').toggleClass("success")

	# Email format validator
	# at least one character followed by '@' followed by at least two characters, '.', at least two characters
	$('input#email').keyup ->
		filter = /(.+)@(.+){2,}\.(.+){2,}/
		if filter.test($(this).val())
			if !$(this).parents('.control-group').hasClass('success')
				$(this).parents('.control-group').toggleClass("success")
		else
			if $(this).parents('.control-group').hasClass('success')
				$(this).parents('.control-group').toggleClass("success")

	# Password length validator
	# Must be at least 8 characters long
	$('input#password').keyup ->
		if $(this).val().length >= 8
			if !$(this).parents('.control-group').hasClass('success')
				$(this).parents('.control-group').toggleClass("success")
		else
			if $(this).parents('.control-group').hasClass('success')
				$(this).parents('.control-group').toggleClass("success")

	# Submit timezone with signup
	timezone = jstz.determine()
	name = timezone.name()
	$('input#timezone').val(name)

	`var _gaq = _gaq || [];
	_gaq.push(['_setAccount', 'UA-30914801-1']);
	_gaq.push(['_trackPageview']);

	(function() {
	  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
	  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
	  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
	})();`

	new FastClick document.body