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

	# Submit timezone with signup
	timezone = jstz.determine()
	name = timezone.name()
	$('input#timezone').val(name)

# End document.ready ----------------------------------------------------------------