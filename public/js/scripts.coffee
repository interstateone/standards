$ ->

	# Prevent iOS from opening a new Safari instance for anchor tags
	# :not selector prevents operating on classes that are listed below
	$(document).on ->
		'click'
		'a[href]:not(.delete, .delete-confirm, .target, .title)'
		(event) ->
			event.preventDefault()
			window.location = $(this).attr "href"

	$(document).on ->
		'tap'
		'a[href]:not(.delete, .delete-confirm, .target, .title)'
		(event) ->
			event.preventDefault()
			window.location = $(this).attr "href"

	# Disable do-nothing links
	$('section [href^=#]').click (e) ->
		e.preventDefault()

	# Add drop shadow to navbar when page is scrolled
	window.onscroll = addDropShadow

	# Use the touchmove event for touch devices because onscroll isn't fired until the scrolling/panning stops
	window.addEventListener('touchmove', addDropShadow, false)

	addDropShadow = ->
		header = $('.navbar')
		if window.pageYOffset > 0
			header.addClass 'nav-drop-shadow'
		else
			header.removeClass 'nav-drop-shadow'

	# Set the timezone dropdown to the current value
	$select = $('select#timezone')
	if $select.data("zone") != null
		$select.val($select.data("zone"))

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

	# If this is the settings page, handle the weekday radio buttons
	# Credit: http://dan.doezema.com/2012/03/twitter-bootstrap-radio-button-form-inputs/
	if $('div.btn-group[data-toggle-name=*]').length
		$('div.btn-group[data-toggle-name=*]').each ->
			group   = $(this)
			form    = group.parents('form').eq(0)
			name    = group.attr('data-toggle-name')
			hidden  = $('input[name="' + name + '"]', form)
			$('button', group).each ->
				button = $(this)
				button.live 'click', ->
					hidden.val($(this).val())
				if button.val() == hidden.val()
					button.addClass 'active'

	# Timezone stuff
	# If the selection is manually changed, turn the button to it's regular color
	$('select[name="timezone"]').change (event) ->
		$button = $('button.geolocate')
		if $button.length
			$button.css('color', '#333333')

	# Check for browser support of geolocation
	if (navigator.geolocation)
		# Display the gelocate button
		$('select[name="timezone"]').parent().append('<button class="btn geolocate" type="button"><i class="icon-map-marker"></i></button>')
		$button = $('button.geolocate')

		# Find the timezone when the button is clicked
		$('button.geolocate').click ->
			# Find the current location
			navigator.geolocation.getCurrentPosition(
				# success function
				->
					# change to seperate function later
					# lookup in geonames
					lat = position.coords.latitude
					long = position.coords.longitude

					urlbase = "http://api.geonames.org/timezoneJSON?"
					username = "interstateone"

					url = urlbase + "lat=" + lat + "&" + "lng=" + long + "&" + "username=" + username

					$.get url, (data) ->
						# success state for geolocate button
						$button.css('color', 'green')

						# select the proper option in the menu
						$('select[name="timezone"]').val(data.timezoneId)
					.error ->
						# error state for geolocate button
						$button.css('color', 'red')

				# error function
				(error) ->
					switch (error.code)
						when error.TIMEOUT then	alert 'Timeout'
						when error.POSITION_UNAVAILABLE then alert 'Position unavailable'
						when error.PERMISSION_DENIED then alert 'Permission denied'
						when error.UNKNOWN_ERROR then alert 'Unknown error'
			)

	# Map JS reset() function to jQuery
	jQuery.fn.reset = ->
		$(this).each -> this.reset()

	# Show new task form when user clicks the plus button
	$('a.add').click (e) ->
		if !$(this).children("i").hasClass("cancel")
			$("input#title").focus()
			$(this).children("i").animate({transform: 'rotate(45deg)'}, 'fast').toggleClass("cancel")
			$(this).css('color', "red")
			$(this).siblings('#newtask').animate({opacity: 1}, 'fast').css("visibility", "visible")
		else
			$(this).children("i").animate({transform: ''}, 'fast').toggleClass("cancel")
			$(this).css('color', "#CCC")
			$(this).siblings('#newtask').animate {opacity: 0}, 'fast', ->
				$(this).css("visibility", "hidden")
				$(this).reset()

	# Submit a new task with the enter key
	$('#newtask > input#purpose').keypress (e) ->
		if e.which == 13
			e.preventDefault()
			$('#newtask').submit()
			_gaq.push(['_trackEvent', 'task', 'create'])

	colorArray = (numberOfRows, lightness) ->
		colors = []

		for i in [0..numberOfRows]
			hue = i * 340 / (numberOfRows + 2)
			saturation = 0.8
			# lightness = 0.5
			alpha = 1.0
			color = $.Color({hue: hue, saturation: saturation, lightness: lightness, alpha: alpha}).toHslaString()
			colors.push($.Color(color).toHexString())
		colors

	renderColors = ->
		rows = $('tbody').children()
		bgColors = colorArray(rows.size(), 0.8)
		barColors = colorArray(rows.size(), 0.6)
		$(rows).each (row) ->
			$ministat = $(this).children('td.title').children('.ministat')
			$ministat.css("background-color", bgColors[row])
			$ministat.children('.minibar').css("background-color", barColors[row])

	renderColors()

	renderHeight = ->
		rows = $('tbody').children()
		$(rows).each (i) ->
			$bar = $(this).children('td.title').children('.ministat').children('.minibar')
			data = $bar.data()
			count = data.count
			total = data.total
			$bar.css("height", Math.min(50 * count / total, 50))

	# If this is the homepage, call renderHeight() once
	if $('td.title').length
		renderHeight()

	incrementHeight = (target) ->
		$bar = $(target).parents('tr').children('td.title').children('.ministat').children('.minibar')

		# Caching the data object is faster than calling it twice (http://api.jquery.com/data/)
		data = $bar.data()
		data.count += 1

		# Rerender the bar heights
		renderHeight()

	decrementHeight = (target) ->
		$bar = $(target).parents('tr').children('td.title').children('.ministat').children('.minibar')

		# Caching the data object is faster than calling it twice (http://api.jquery.com/data/)
		data = $bar.data()
		data.count -= 1
		# Rerender the bar heights

		renderHeight()

	# Post a new task
	$('#newtask').submit (e) ->
		e.preventDefault()
		$.post "/new", $(this).serialize(), (data) ->
				# Append the new task row
				$('tbody').append(data)

				# Remove welcome message after submitting first task
				$('.hero-unit').hide()

				renderColors()

				$('a.add').children('i').animate({transform: ''}, 'fast').toggleClass("cancel")
				$('a.add').css('color', "#CCC").siblings('#newtask').animate {opacity: 0}, 'fast', ->
					$(this).reset()
			, "text"

	# Delete a task modal
	$(document).on "click", 'a.delete', (e) ->
		$(this).siblings(".deleteModal").modal()

	# Delete a task
	$(document).on "click", 'a.delete-confirm', (e) ->
		clicked = this
		e.preventDefault()
		$.post(clicked.href, { _method: 'delete' }, (data) ->
				$(this).parents(".deleteModal").modal('hide')
				window.location.pathname = "/"
		, "script")

	# Set the delete button in the delete task modal to be stateful
	$(document).on "click", ".delete-confirm", ->
		$('.delete-confirm').button('loading')

	# Check a task
	$(document).on "click", 'a.target', (e) ->
		clicked = this
		e.preventDefault()
		$(clicked).children('img').toggleClass("complete")
		if $(clicked).children('img').hasClass("complete")
			incrementHeight(clicked)
			_gaq.push(['_trackEvent', 'check', 'complete'])
		else
			decrementHeight(clicked)
			_gaq.push(['_trackEvent', 'check', 'uncomplete'])

		$.post clicked.href, null, (data) ->
			if data != ''
				$(clicked).children('img').toggleClass("complete")
				if $(clicked).children('img').hasClass("complete")
					incrementHeight(clicked)
				else
					decrementHeight(clicked)
		.error ->
			$(clicked).children('img').toggleClass("complete")

	# Let forgot password button make post to alternate route than submitting the login
	$('button.forgot').click (e) ->
		e.preventDefault()
		$(this).parents('form').attr("action", '/forgot')
		$(this).parents('form').submit()

	# Submit timezone with signup
	timezone = jstz.determine_timezone()
	name = timezone.name()
	$('input#timezone').val(name)

# End document.ready ----------------------------------------------------------------