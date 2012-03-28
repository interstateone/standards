require 'bundler/setup'
Bundler.require(:default)

SITE_TITLE = "Standards"

use Rack::Session::Cookie, :expire_after => 2592000
set :session_secret, ENV['SESSION_KEY'] || "i_have_a_lovely_bunch_of_c0c0nu7s"

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://brandon:rb26dett@localhost/standards")

# Configure test database
configure :test do
	DataMapper.setup(:default, "sqlite::memory:")
end

class User
	include DataMapper::Resource

	has n, :tasks
	has n, :checks

	property :id, Serial
	property :email, String, :required => true, :unique => true
	property :password, BCryptHash, :required => true
	property :created_on, Date, :default => proc { Date.today }

end

class Task
	include DataMapper::Resource

	belongs_to :user
	has n, :checks

	property :id, Serial
	property :title, Text, :required => true
	property :created_on, Date, :default => proc { Date.today }
end

class Check
	include DataMapper::Resource

	belongs_to :user
	belongs_to :task

	property :id, Serial
	property :date, Date
end

DataMapper.finalize.auto_upgrade!

helpers do
	def login?
		if session[:email].nil?
			return false
		else
			return true
		end
	end

	def email
		return session[:email]
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

	def valid_password?(password)

	end
end

get '/' do
	if login?
		@user = User.first :email => session[:email]
		@tasks = @user.tasks
		@checks = @user.checks
		erubis :home
	else
		erubis :index
	end
end

post '/' do
	if login?
		@user = User.first :email => session[:email]
		@task = Task.new
		@task.title = params[:tasktitle]
		@task.user = @user
		@task.save

		erubis :task_row_short, :layout => false
	else
		erubis :index
	end
end

get '/edit' do
	if login?
		@user = User.first :email => session[:email]
		@tasks = @user.tasks
		erubis :edit
	else
		erubis :index
	end
end

get '/stats/?' do
	if login?
		@user = User.first :email => session[:email]
		@tasks = @user.tasks
		@checks = @user.checks
		erubis :stats
	else
		erubis :index
	end
end

get "/signup" do
  erubis :signup
end

post "/signup" do
	# Validate the fields first
	# Don't worry about existing emails, we'll handle that later
	if !valid_email? params[:email]
		flash.now[:error] = "Please enter a valid email address."
		erubis :signup
	else
		# Try creating a new user
		user = User.new
		user.email = params["email"]
		user.password = params["password"]
		if user.save
			# Log in and redirect if everything went okay
			session[:email] = params[:email]
			redirect "/"
		else
			# If the user already exists, try logging them in
			if User.first :email => params[:email]
				user = User.first :email => params[:email]
				if user.password == params[:password]
					session[:email] = params[:email]
					redirect "/"
				end
			# Not an existing valid user, throw the signup errors
			else
				flash.now[:error] = user.errors.join " "
				erubis :signup
			end
		end
	end
end

get "/login" do
	erubis :login
end

post "/login" do
	if User.first :email => params[:email]
		user = User.first :email => params[:email]
		if user.password == params[:password]
			session[:email] = params[:email]
			redirect "/"
		end
	end
	flash.now[:error] = "Email and password don't match."
	erubis :login
end

get "/logout" do
  session[:email] = nil
  redirect "/"
end

post "/forgot" do
	if !valid_email? params[:email]
		flash.now[:error] = "Please enter an email address."
		erubis :login
	else

	end
end

get '/:id' do
	if login?
		@user = User.first :email => session[:email]
		@task = @user.tasks.get params[:id]
		if @task
			erubis :task
		else
			status 404
			flash.now[:error] = "That task can't be found."
			erubis :home
		end
	else
		flash.now[:error] = "Please log in to access that task."
		erubis :index
	end
end

post '/:id/:date/complete' do
	if login?
		user = User.first :email => session[:email]
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
	else
		erubis :index
	end
end

post '/:id/rename' do
	if login?
		user = User.first :email => session[:email]
		t = user.tasks.get params[:id]
		if t != nil
			t.title = params[:title]
			if t.save
				true
			else
				flash.now[:error] = "Something went wrong trying to rename that task."
				erubis :flash, :layout => false
			end
		else
			flash.now[:error] = "That task doesn't exist."
			erubis :flash, :layout => false
		end
	else
		flash.now[:error] = "Please sign in to perform that action."
		erubis :flash, :layout => false
	end
end

delete '/:id/delete' do
	if login?
		user = User.first :email => session[:email]
		t = user.tasks.get params[:id]
		t.checks.destroy
		t.destroy
	else
		erubis :index
	end
end

not_found do
	status 404
end

error do
	status 500
end