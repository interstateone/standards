require 'sinatra/base'

class Hash
	def only(*whitelist)
		reject {|key, value| !whitelist.include?(key) }
	end
end

class API < Sinatra::Base

	require 'bundler/setup'
	Bundler.require()
	require 'yaml'
	require 'active_support/core_ext/time/zones'
	require 'active_support/time_with_zone'
	require 'active_support/core_ext/time/conversions'
	require_relative 'workers/emailworker'

	use Rack::Cache
	use Rack::Deflater
	set :public_folder, 'public'

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

	require_relative 'models/init'
	require_relative 'helpers/api_helpers'
	helpers Sinatra::ApiHelpers

	before do
		if logged_in?
			Time.zone = current_user.timezone
		end
	end

	# ------------------------------------------------
	#
	# Authentication Routes
	#
	# ------------------------------------------------

	# Sign In

	post "/sign-in/?" do
		if user = User.authenticate(params[:email], params[:password])
			content_type :json
			session[:id] = user.id
			user.attributes.only(:id, :name, :email, :starting_weekday, :timezone).to_json
		else
			status 401
		end
	end

	# Sign Out

	post "/sign-out/?" do
		content_type :json
		session[:id] = nil
	end

	# ------------------------------------------------
	#
	# User Routes
	#
	# ------------------------------------------------

	# Create User ------------------------------------

	post "/user/?" do
		content_type :json

		# Validate the email field
		if !valid_email? params[:email]
			# invalid input status
			status 422
			{ :error => "Please enter a valid email address." }.to_json
		else
			# Try creating a new user
			user = User.new
			user.name = params[:name]
			user.email = params[:email]
			user.password = params[:password]

			# If user already exists, sign them in
			if existing_user = User.authenticate(params[:email], params[:password])

				session[:id] = existing_user.id
				existing_user.to_json

			# If user doesn't exist but is a valid new user, sign them up
			elsif user.save

				# Set the session id to the new user and return it
				session[:id] = user.id
				user.to_json

			# If user doesn't exists and is not a valid new user, throw errors
			else
				# Invalid input status
				status 422
				# Return the errors
				user.errors.to_json
			end
		end
	end

	# Read User --------------------------------------

	get "/user/info/?" do
		content_type :json
		login_required
		current_user.attributes.only(:id, :name, :email, :starting_weekday, :timezone, :email_permission).to_json
	end

	# Forgot password --------------------------------

	post "/user/forgot/?" do
		unless valid_email? params[:email]
			content_type :json
			{
				'status' => 'error',
				'error' => 'invalid email'
			}.to_json
		else
			user = User.first(:email => params[:email])
			unless user.nil?
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

				content_type :json
				{
					'status' => 'success',
					'message' => 'You\'ve been sent a password reset email to the address you provided, click the link inside to do so.'
				}.to_json
			else
				content_type :json
				{
					'status' => 'error',
					'message' => 'invalid email'
				}.to_json
			end
		end
	end

	# Reset password

	post '/user/reset/?' do
		user = User.first :password_reset_key => params[:key]
		if !user.nil?
			user.password = params[:password]
			user.password_reset_key = nil
			user.save
			session[:id] = user.id

			content_type :json
			{
				'status' => 'success',
				'message' => 'Great! Your password has been changed'
			}.to_json
		else
			content_type :json
			{
				'status' => 'error',
				'message' => 'That isn\'t a valid password reset link.'
			}.to_json
		end
	end

	get '/user/reset/:key/?' do
		@user = User.first :password_reset_key => params[:key]
		if !@user.nil?
			erb :reset_password
		else
			flash[:error] = "That is not a valid password reset link."
			redirect '/'
		end
	end

	# Update User ------------------------------------

	put "/user/info/?" do

		login_required
		user = current_user
		data = JSON.parse request.body.read.to_s

		# Update info
		user.update(
			:name => data['name'],
			:email => data['email'],
			:starting_weekday => data['starting_weekday'],
			:timezone => data['timezone'],
			:email_permission => data['email_permission'] || false
		)

		user.attributes.only(:id, :name, :email, :starting_weekday, :timezone, :email_permission).to_json
	end

	# Update Password --------------------------------

	post '/user/password/?' do
		login_required
		data = JSON.parse request.body.read.to_s

		if user = User.authenticate(current_user.email, data['current_password'])
			user.password = data['new_password']
			user.save
		else
			halt 401
		end
		return true
	end

	# Delete User ------------------------------------

	delete "/user/:id/?" do

		login_required

		# If the authenticated user is the one we're looking for, delete it
		if session[:id] == params[:id]
			user = current_user

			# Destroy the associated checks and tasks, and then the user
			user.checks.destroy
			user.tasks.destroy
			User.get(user.id).destroy

			# Destroy the session
			session[:id] = nil
		else
			# Otherwise return an unauthorized status
			status 401
		end

	end

	# ------------------------------------------------
	#
	# Task Routes
	#
	# ------------------------------------------------

	get '/tasks/?' do
		content_type :json

		login_required

		current_user.tasks.to_json :methods => [:checks]
	end

	post '/tasks/?' do
		content_type :json
		login_required
		data = JSON.parse request.body.read.to_s
		user = current_user
		task = Task.create(:title => data['title'], :purpose => data['purpose'], :user => user).to_json
	end

	get '/tasks/:id/?' do
		content_type :json

		login_required

		current_user.tasks.get(params[:id]).to_json :methods => [:checks]
	end

	delete '/tasks/:id/?' do
		login_required
		user = current_user
		task = user.tasks.get params[:id]
		task.checks.destroy
		task.destroy
		true
	end

	# ------------------------------------------------
	#
	# Check Routes
	#
	# ------------------------------------------------

	delete '/checks/:id/?' do
		login_required
		user = current_user
		c = user.checks.get params[:id]
		c.destroy unless c.nil?
	end

	post '/checks/?' do
		content_type :json
		login_required
		data = JSON.parse request.body.read.to_s
		user = current_user
		task = user.tasks.get data['task']['id']
		if task.checks.count(:date => data['date']) == 0
			check = Check.create(:user => user, :task => task, :date => data['date']).to_json
		end
	end

	# ------------------------------------------------
	#
	# Misc. Routes
	#
	# ------------------------------------------------

	get '/timezones/?' do
		content_type :json
		result = []
		TZInfo::Timezone.all.each do |zone|
			result.push zone.identifier => zone
		end
		result.to_json
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
		@user = current_user
		@task = @user.tasks.create(:title => params[:title], :purpose => remove_trailing_period(params[:purpose]))

		if !@task.saved?
			flash[:error] = @task.errors.to_a
		end

		erb :task_row, :layout => false
	end

	get '/stats/?' do
		login_required
		@user = current_user
		@tasks = @user.tasks
		@checks = @user.checks
		erb :stats
	end

	get '/about/?' do
		erb :about
	end

	get '/admin/?' do
		login_required
		@user = current_user
		if @user.admin?
			# Garb Setup
			Garb::Session.login(ENV['ANALYTICS_USERNAME'] || settings.analytics_username, ENV['ANALYTICS_PASSWORD'] || settings.analytics_password)
			profile = Garb::Management::Profile.all.detect {|p| p.web_property_id == 'UA-30914801-1'}

			class Exits
				extend Garb::Model

				metrics :pageviews, :visitors
				dimensions :page_path, :referral_path, :city
			end

			today_in_time_zone = Time.zone.now.to_date
			month = profile.exits
			week = profile.exits(:start_date => (today_in_time_zone - 7), :end_date => today_in_time_zone)
			today = profile.exits(:start_date => today_in_time_zone)

			# Grab GA metrics
			@visitors_month = month.inject(0) {|sum, record| sum + record.visitors.to_i}
			@visitors_week = week.inject(0) {|sum, record| sum + record.visitors.to_i}
			@visitors_today = today.inject(0) {|sum, record| sum + record.visitors.to_i}
			@pageviews_month = month.inject(0) {|sum, record| sum + record.pageviews.to_i}
			@pageviews_week = week.inject(0) {|sum, record| sum + record.pageviews.to_i}
			@pageviews_today = today.inject(0) {|sum, record| sum + record.pageviews.to_i}

			# Grab DB metrics
			@user_count = User.all.count
			@new_users_this_week = User.all(:created_on.gte => (today_in_time_zone - 7)).count
			@check_count = Check.all.count
			checks_this_week = Check.all(:created_at.gte => (today_in_time_zone - 7))
			@new_checks_this_week = checks_this_week.count
			# users that have checked in the last week
			# inject returns array of unique users
			seen = Set.new
			unique_users = checks_this_week.users.inject([]) do |unique, user|
				unless seen.include?(user.id)
					unique << user
					seen << user.id
				end
				unique
			end
			@active_users_this_week = unique_users.length

			erb :admin
		else
			redirect '/'
		end
	end

	get '/:id/?' do
		login_required
		@user = current_user
		@task = @user.tasks.get params[:id]
		if @task
			# Make an array of checks sorted by weekday
			@weekdayTemperatures = [0,0,0,0,0,0,0]
			@maxTemp = 0;
			@minTemp = 0;
			@task.checks(:order => :date.asc).each do |check|
				weekdayIndex = check.date.wday
				@weekdayTemperatures[weekdayIndex] += 1
				if @weekdayTemperatures[weekdayIndex] > @maxTemp
					@maxTemp += 1
				end
			end

			if @maxTemp < 1
				@maxTemp = 1
			end
			@minTemp = @weekdayTemperatures.sort.first

			erb :task
		else
			flash[:error] = "That task can't be found."
			redirect '/'
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

	# Error routes #################################################################

	not_found do
		status 404
	end

	error do
		status 500
	end

end