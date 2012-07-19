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

	use Rack::Cache
	use Rack::Deflater

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