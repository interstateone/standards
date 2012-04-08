require 'bundler/setup'
Bundler.require()
require 'yaml'
require 'active_support/core_ext/time/zones'
require 'active_support/time_with_zone'
require 'active_support/core_ext/time/conversions'
require_relative 'workers/emailworker'

SITE_TITLE = "Standards"

configure :production do
	DataMapper.setup(:default, ENV['DATABASE_URL'])
	use Rack::Session::Cookie, :expire_after => 2592000
	set :session_secret, ENV['SESSION_KEY']
end

configure :development do
	yaml = YAML.load_file("config.yaml")
	yaml.each_pair do |key, value|
		set(key.to_sym, value)
	end

	DataMapper.setup(:default, "postgres://" + settings.db_user + ":" + settings.db_password + "@" + settings.db_host + "/" + settings.db_name)
	use Rack::Session::Cookie, :expire_after => 2592000
	set :session_secret, settings.session_secret
end

IronWorker.configure do |config|
	config.token = ENV['IRON_WORKER_TOKEN']
	config.project_id = ENV['IRON_WORKER_PROJECT_ID']
end

class User
	include DataMapper::Resource

	has n, :tasks
	has n, :checks

	property :id, Serial
	property :name, String, :required => true
	property :email, String, :required => true, :unique => true
	property :hashed_password, String
	property :salt, String
	property :permission_level, Integer, :default => 1
	property :password_reset_key, String
	property :timezone, String

	timestamps :on

	validates_presence_of :name
	validates_presence_of :email
	validates_uniqueness_of :email
	validates_presence_of :hashed_password, :message => "Password must be at least 8 characters with one number."

	before :save do

	end

	def password=(pass)
		if valid_password? pass
			@password = pass
			self.salt = User.random_string(10) if !self.salt
			self.hashed_password = User.encrypt(@password, self.salt)
		end
	end

	def admin?
		self.permission_level == -1 || self.id == 1
	end

	def self.authenticate(email, pass)
		user = first :email => email
		return nil if user.nil?
		return user if User.encrypt(pass, user.salt) == user.hashed_password
		nil
	end

	protected

	def self.encrypt(pass, salt)
		Digest::SHA1.hexdigest(pass+salt)
	end

	def self.random_string(len)
		#generate a random password consisting of strings and digits
		chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
		newpass = ""
		1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
		return newpass
	end

	def valid_password?(password)
		reg = /^(?=.*\d)(?=.*([a-z]|[A-Z]))([\x20-\x7E]){8,40}$/
		return (reg.match(password))? true : false
	end
end

class Task
	include DataMapper::Resource

	belongs_to :user
	has n, :checks

	property :id, Serial
	property :title, Text, :required => true
	property :purpose, Text

	timestamps :on
end

class Check
	include DataMapper::Resource

	belongs_to :user
	belongs_to :task

	property :id, Serial
	property :date, Date

	timestamps :at
end

DataMapper.finalize.auto_upgrade!

helpers do
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
			return false
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

before do
	if logged_in?
		Time.zone = current_user.timezone
	end
end

get '/' do
	if logged_in?
		@user = current_user
		@tasks = @user.tasks
		@checks = @user.checks
		erb :home
	else
		erb :index
	end
end

get '/new/?' do
	login_required
	@user = current_user
	erb :new
end

post '/new/?' do
	login_required
	user = current_user
	task = user.tasks.create(:title => params[:tasktitle], :purpose => remove_trailing_period(params[:taskpurpose]))

	task.errors.each do |e|
		flash[:error] = e
	end

	redirect '/'
end

get '/stats/?' do
	login_required
	@user = current_user
	@tasks = @user.tasks
	@checks = @user.checks
	erb :stats
end

get '/settings/?' do
	login_required
	@user = current_user
	@task_count = @user.tasks.count
	@check_count = @user.checks.count
	erb :settings
end

get '/about/?' do
	erb :about
end

get "/signup/?" do
  erb :signup
end

post "/signup/?" do
	# Validate the fields first
	# Don't worry about existing emails, we'll handle that later
	if !valid_email? params[:email]
		flash[:error] = "Please enter a valid email address."
		redirect '/signup'
	else
		# Try creating a new user
		user = User.new
		user.name = params[:name]
		user.email = params[:email]
		user.password = params[:password]
		user.timezone = params[:timezone]
		if user.save
			# Flash thank you, sign in and redirect
			session[:id] = user.id
			flash[:notice] = "Thanks for signing up!"
			redirect "/"
		else
			user.errors.each do |e|
				flash[:error] = e
			end
			redirect '/signup'
		end
	end
end

get "/login/?" do
	erb :login
end

post "/login/?" do
	if user = User.authenticate(params[:email], params[:password])
		session[:id] = user.id
		if session[:return_to]
			redirect_url = session[:return_to]
			session[:return_to] = false
			redirect redirect_url
		else
			redirect '/'
		end
	end
	flash.now[:error] = "Email and password don't match."
	erb :login
end

get "/logout/?" do
  session[:id] = nil
  redirect "/"
end

post "/forgot/?" do
	if !valid_email? params[:email]
		flash[:error] = "Please enter the email address you signed up with."
		redirect '/login'
	else
		user = User.first(:email => params[:email])
		if !user.nil?
			@key = user.password_reset_key = Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..20]
			user.save

			@name = user.name
			@url = ENV['CONFIRMATION_CALLBACK_URL'] || settings.confirmation_callback_url

			resetWorker = EmailWorker.new
			resetWorker.username = ENV['EMAIL_USERNAME'] || settings.email_username
			resetWorker.password = ENV['EMAIL_PASSWORD'] || settings.email_password
			resetWorker.to = user.email
			resetWorker.from = ENV['EMAIL_USERNAME'] || settings.email_username
			resetWorker.subject = "Reset your Standards password"
			resetWorker.body = erb :reset_password_email, :layout => false

			if production?
				resetWorker.queue
			else
				resetWorker.run_local
			end

			flash[:notice] = "You've been sent a password reset email to the address you provided, click the link inside to do so."
			redirect "/"
		end
	end
end

get '/reset/:key/?' do
	@user = User.first :password_reset_key => params[:key]
	if !@user.nil?
		erb :reset_password
	else
		flash[:error] = "That is not a valid password reset link."
		redirect '/'
	end
end

post '/reset/?' do
	user = User.first :password_reset_key => params[:key]
	if !user.nil?
		user.password = params[:password]
		user.password_reset_key = nil
		user.save
		session[:id] = user.id
		flash[:notice] = "Great! You're password has been changed."
		redirect '/'
	else
		flash[:error] = "That is not a valid password reset link."
		redirect '/'
	end
end

post '/change-info/?' do
	login_required
	user = current_user
	user.name = params[:name]
	user.email = params[:email]
	user.save
	flash[:notice] = "Great! Your info has been updated."
	redirect '/settings'
end

post '/change-password/?' do
	login_required
	if user = User.authenticate(current_user.email, params[:current_password])
		user.password = params[:new_password]
		user.save
		flash[:notice] = "Great! Your password has been changed."
		redirect '/settings'
	else
		flash[:error] = "That password was incorrect."
		redirect '/settings'
	end
end

get '/:id/?' do
	login_required
	@user = current_user
	@task = @user.tasks.get params[:id]
	if @task
		erb :task
	else
		status 404
		flash.now[:error] = "That task can't be found."
		erb :home
	end
end

post '/:id/:date/complete/?' do
	login_required
	user = current_user
	t = user.tasks.get params[:id]
	if t.checks(:date => params[:date]).count > 0
		c = t.checks :date => params[:date]
		c.destroy
	else
		c = Check.new
		c.date = params[:date]
		c.task = t
		c.user = user
		c.save
		t.save
	end
end

post '/:id/rename/?' do
	login_required
	user = current_user
	t = user.tasks.get params[:id]
	if t != nil
		t.title = params[:title]
		if t.save
			true
		else
			flash.now[:error] = "Something went wrong trying to rename that task."
			erb :flash, :layout => false
		end
	else
		flash.now[:error] = "That task doesn't exist."
		erb :flash, :layout => false
	end
end

delete '/:id' do
	login_required
	user = current_user
	task = user.tasks.get params[:id]
	task.checks.destroy
	task.destroy

	flash[:notice] = "Task deleted."
	true
end

# Error routes #################################################################

not_found do
	status 404
end

error do
	status 500
end