require 'bundler/setup'
Bundler.require(:default)
require 'yaml'
require 'redis'

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

configure do
	uri = URI.parse(ENV["REDISTOGO_URL"] || "redis://redistogo:442f5dade51e21393456f3b11017045f@herring.redistogo.com:9189/")
	REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
	Resque.redis = REDIS
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
	property :confirmed_at, DateTime
	property :confirmation_key, String, :default => lambda { |r,p| Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..20] }
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

	def confirmed?
		!!confirmed_at
	end

	def confirm!
		if !self.confirmed?
			self.confirmation_key = nil
			self.confirmed_at = Time.now.utc
			self.save
		else
			false
		end
	end

	def self.authenticate(email, pass)
		user = first :email => email
		return nil if user.nil?
		return nil if !user.confirmed?
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

module HerokuResqueAutoScale
	module Scaler
		class << self
			@@heroku = Heroku::Client.new(ENV['HEROKU_USER'], ENV['HEROKU_PASS'])

			def workers
				if production?
					@@heroku.ps(ENV['HEROKU_APP']).count { |a| a["process"] =~ /worker/ }
				end
			end

			def workers=(qty)
				if production?
					@@heroku.ps_scale(ENV['HEROKU_APP'], :type=>'worker', :qty=>qty)
				end
			end

			def job_count
				Resque.info[:pending].to_i
			end
		end
	end

	def after_perform_scale_down(*args)
		# Nothing fancy, just shut everything down if we have no jobs
		Scaler.workers = 0 if Scaler.job_count.zero?
	end

	def after_enqueue_scale_up(*args)
		[
			{
				:workers => 1, # This many workers
				:job_count => 1 # For this many jobs or more, until the next level
			},
			{
				:workers => 2,
				:job_count => 15
			},
			{
				:workers => 3,
				:job_count => 25
			},
			{
				:workers => 4,
				:job_count => 40
			},
			{
				:workers => 5,
				:job_count => 60
			}
		].reverse_each do |scale_info|
		# Run backwards so it gets set to the highest value first
		# Otherwise if there were 70 jobs, it would get set to 1, then 2, then 3, etc

		# If we have a job count greater than or equal to the job limit for this scale info
		if Scaler.job_count >= scale_info[:job_count]
			# Set the number of workers unless they are already set to a level we want. Don't scale down here!
			if Scaler.workers <= scale_info[:workers]
				Scaler.workers = scale_info[:workers]
			end
			break # We've set or ensured that the worker count is high enough
		end
	end
end
end

module ConfirmEmailJob
	extend HerokuResqueAutoScale

	@queue = :confirmation_email

	def self.perform(id)
    	@user = User.get id
		@url = ENV['CONFIRMATION_CALLBACK_URL'] || settings.confirmation_callback_url
		template  = File.read 'views/confirmation_email.erb'
		Pony.mail({
			:to => @user.email,
			:subject => "Confirm your Standards account",
			:via => :smtp,
			:via_options => {
				:address              => 'smtp.gmail.com',
				:port                 => '587',
				:enable_starttls_auto => true,
				:user_name            => ENV['EMAIL_USERNAME'] || settings.email_username,
				:password             => ENV['EMAIL_PASSWORD'] || settings.email_password,
				:authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
				:domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
			},
			:html_body => ERB.new(template).result(binding)
		}) unless :environment == :test
	end
end

helpers do
	def logged_in?
		user = User.get session[:id]
		!user.nil?
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
			session[:return_to] = request.fullpath
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

	def send_confirmation_email(user)
		@user = user
		@url = ENV['CONFIRMATION_CALLBACK_URL'] || settings.confirmation_callback_url
		Pony.mail({
			:to => user.email,
			:subject => "Confirm your Standards account",
			:via => :smtp,
			:via_options => {
				:address              => 'smtp.gmail.com',
				:port                 => '587',
				:enable_starttls_auto => true,
				:user_name            => ENV['EMAIL_USERNAME'] || settings.email_username,
				:password             => ENV['EMAIL_PASSWORD'] || settings.email_password,
				:authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
				:domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
			},
			:html_body => erb(:confirmation_email, :layout => false)
		}) unless :environment == :test
	end

	def send_password_reset_email(user)
		@user = user
		@url = ENV['CONFIRMATION_CALLBACK_URL'] || settings.confirmation_callback_url
		Pony.mail({
			:to => user.email,
			:subject => "Change your Standards account password",
			:via => :smtp,
			:via_options => {
				:address              => 'smtp.gmail.com',
				:port                 => '587',
				:enable_starttls_auto => true,
				:user_name            => ENV['EMAIL_USERNAME'] || settings.email_username,
				:password             => ENV['EMAIL_PASSWORD'] || settings.email_password,
				:authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
				:domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
			},
			:html_body => erb(:reset_password_email, :layout => false)
		}) unless :environment == :test
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
			# Send confirmation job through Resque
			Resque.enqueue(ConfirmEmailJob, user.id)

			# Flash confirmation info and redirect
			flash[:notice] = "You've been sent a confirmation email to the address you provided, click the link inside to get started."
			redirect "/"
		else
			user.errors.each do |e|
				flash[:error] = e
			end
			redirect '/signup'
			# # If the user already exists, try logging them in
			# if user = User.authenticate(params[:email], params[:password])
			# 	session[:email] = params[:email]
			# 	if session[:return_to]
			# 		redirect_url = session[:return_to]
			# 		session[:return_to] = false
			# 		redirect redirect_url
			# 	else
			# 		redirect '/'
			# 	end
			# end
		end
	end
end

get '/confirm/:key/?' do
	user = User.first :confirmation_key => params[:key]
	if !user.nil?
		if user.confirm!
			session[:id] = user.id
			flash[:notice] = "Thanks! You're ready to get started."
			redirect '/'
		else
			flash[:error] = "It seems like that email address has already been confirmed."
			redirect '/login'
		end
	else
		flash[:error] = "That is not a valid confirmation link."
		redirect '/'
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
			# Time.zone = user.timezone
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
			user.password_reset_key = Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..20]
			user.save
			send_reset_password_email user
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
		flash[:notice] = "Great! You're good to go."
		redirect '/'
	else
		flash[:error] = "That is not a valid password reset link."
		redirect '/'
	end
end

get '/change/?' do
	login_required
	@user = current_user
	erb :change_password
end

post '/change/?' do
	login_required
	user = current_user
	user.password = params[:password]
	user.save
	flash[:notice] = "Your password has been changed!"
	redirect '/'
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

delete '/:id/delete' do
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