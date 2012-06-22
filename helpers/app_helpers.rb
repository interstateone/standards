helpers do
	include Rack::Utils
	alias_method :h, :escape_html

	def logged_in?
		user = User.get session[:id]
		return true unless user.nil?
		return false
	end

	def current_user
		user = User.get session[:id]
		return user unless user.nil?
	end

	def login_required
		#not as efficient as checking the session. but this inits the fb_user if they are logged in
		if current_user != nil
			return true
		else
			session[:return_to] = request.url
			redirect '/login'
			return false
		end
	end

	def valid_email?(email)
		if email =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
			domain = email.match(/\@(.+)/)[1]
			Resolv::DNS.open do |dns|
				@mx = dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
			end
			@mx.size > 0 ? true : false
		else
			false
		end
	end

	def switch_pronouns(string)
		string.gsub(/\b(I am|You are|I|You|Your|My)\b/i) do |pronoun|
			case pronoun.downcase
				when 'i'
					'you'
				when 'you'
					'I'
				when 'i am'
					"You are"
				when 'you are'
					'I am'
				when 'your'
					'my'
				when 'my'
					'your'
			end
		end
	end

	def remove_trailing_period(string)
		string.chomp('.') if (string)
	end

	def pluralize(number, text)
		return text.pluralize if number != 1
		text
	end

	# Next two functions are not mine, probably easier than using ActiveSupport for it though
	# From: https://github.com/toolmantim/bananajour/blob/master/lib/bananajour/helpers.rb
	# Credit to https://github.com/toolmantim
	def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
		from_time = from_time.to_time if from_time.respond_to?(:to_time)
		to_time = to_time.to_time if to_time.respond_to?(:to_time)
		distance_in_minutes = (((to_time - from_time).abs)/60).round
		distance_in_seconds = ((to_time - from_time).abs).round

		case distance_in_minutes
		when 0..1
			return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
			case distance_in_seconds
			when 0..4   then 'less than 5 seconds'
			when 5..9   then 'less than 10 seconds'
			when 10..19 then 'less than 20 seconds'
			when 20..39 then 'half a minute'
			when 40..59 then 'less than a minute'
			else             '1 minute'
			end

		when 2..44           then "#{distance_in_minutes} minutes"
		when 45..89          then 'about 1 hour'
		when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
		when 1440..2879      then '1 day'
		when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
		when 43200..86399    then 'about 1 month'
		when 86400..525599   then "#{(distance_in_minutes / 43200).round} months"
		when 525600..1051199 then 'about 1 year'
		else                      "over #{(distance_in_minutes / 525600).round} years"
		end
	end

	# Like distance_of_time_in_words, but where <tt>to_time</tt> is fixed to <tt>Time.now</tt>.
	#
	# ==== Examples
	#   time_ago_in_words(3.minutes.from_now)       # => 3 minutes
	#   time_ago_in_words(Time.now - 15.hours)      # => 15 hours
	#   time_ago_in_words(Time.now)                 # => less than a minute
	#
	#   from_time = Time.now - 3.days - 14.minutes - 25.seconds     # => 3 days
	def time_ago_in_words(from_time, include_seconds = false)
		distance_of_time_in_words(from_time, Time.now, include_seconds)
	end

	def link_to(url,text=url,opts={})
		attributes = ""
		opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
		"<a href=\"#{url}\" #{attributes}>#{text}</a>"
	end

	# Input: Seed number (i.e. task count)
	# Output Array of color strings in CSS hex format e.g. #FFFFFF
	def color_array(seed)
		colors = Array.new
		(0..seed-1).each do |i|
			colors.push Colorist::Color.from_hsv(360 / (seed) * i + (seed * 6), 0.8, 1).to_s
		end
		return colors
	end
end