require 'sinatra/base'

class Standards < Sinatra::Base

	require 'bundler/setup'
	Bundler.require()
	require 'yaml'
	require 'active_support/core_ext/time/zones'
	require 'active_support/time_with_zone'
	require 'active_support/core_ext/time/conversions'
	include Colorist
	require_relative 'workers/emailworker'
	register Sinatra::Flash

	if memcache_servers = ENV["MEMCACHE_SERVERS"]
	  use Rack::Cache
		set :static_cache_control, [:public, :max_age => 300]
	end
	use Rack::Deflater
	set :public_folder, 'public'

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

	require_relative 'models/init'
	require_relative 'helpers/app_helpers'
	helpers Sinatra::AppHelpers

	before do
		if logged_in?
			Time.zone = current_user.timezone
		end

		if ENV['RACK_ENV'] == 'production'
			@host = 'https://' + request.host
		else
			@host = ''
		end
	end

	get "/signup/?" do
	  erb :signup
	end

	post "/signup/?" do
	  # Validate the fields first
	  # Don't worry about existing emails, we'll handle that later
    # Try creating a new user
    user = User.new
    user.name = params[:name]
    user.email = params[:email]
    user.password = params[:password]
    # If user already exists, sign them in
    if existing_user = User.authenticate(params[:email], params[:password])
      session[:id] = existing_user.id
      if session[:return_to]
        redirect_url = session[:return_to]
        session[:return_to] = false
        redirect redirect_url
      else
        redirect '/'
      end
    # If user doesn't exist but is a valid new user, sign them up
    elsif user.save
      # Flash thank you, sign in and redirect
      session[:id] = user.id
      flash[:notice] = "Thanks for signing up!"
      redirect "/"
    # If user doesn't exists and is not a valid new user, throw errors
    else
      user.errors.each do |e|
        flash[:error] = e
      end
      redirect '/signup'
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
		if params[:email].nil? or params[:email] == ''
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

	get '/*' do
		if logged_in?
			@user = current_user
			@tasks = @user.tasks
			@checks = @user.checks
			erb :home, :layout => :app
		else
			erb :index
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