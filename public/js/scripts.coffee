$ ->

  # Prevent iOS from opening a new Safari instance for anchor tags unless pointing to external page
  $(document).on 'click tap', 'a[href]', (event) ->
    unless ~$(event.target).attr('href').indexOf('http:')
      event.preventDefault()
      window.location = $(event.target).attr('href')

  # Let forgot password button make post to alternate route than submitting the login
  $('button.forgot').click (e) ->
    e.preventDefault()
    $(this).parents('form').attr("action", 'https://mystandards.herokuapp.com/forgot')
    $(this).parents('form').submit()

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

  new FastClick document.body
