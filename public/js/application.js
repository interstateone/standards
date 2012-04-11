!function ($) {
	$(function(){
		// Disable do-nothing links
		$('section [href^=#]').click(function (e) {
			e.preventDefault()
		})
	})
}(window.jQuery)