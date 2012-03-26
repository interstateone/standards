require 'bundler/setup'
Bundler.require(:default)

SITE_TITLE = "Standards"
enable :sessions

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://brandon:rb26dett@localhost/standards")

class User
	include DataMapper::Resource

	has n, :tasks
	has n, :checks

	property :id, Serial
	property :email, String, :required => true, :unique => true
	property :password, BCryptHash, :required => true
	property :created_on, Date, :default => proc { Date.now }

end

class Task
	include DataMapper::Resource

	belongs_to :user
	has n, :checks

	property :id, Serial
	property :title, Text, :required => true
	property :date_created, Date
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
end

get '/' do
	if login?
		@user = User.first :email => session[:email]
		@tasks = @user.tasks
		@checks = @user.checks
		erb :home
	else
		erb :index
	end
end

post '/' do
	if login?
		@user = User.first :email => session[:email]
		@task = Task.new
		@task.title = params[:tasktitle]
		@task.date_created = Date.today
		@task.user = @user
		@task.save

		erb :task_row_short, :layout => false
	else
		erb :index
	end
end

get '/edit' do
	if login?
		@user = User.first :email => session[:email]
		@tasks = @user.tasks
		erb :edit
	else
		erb :index
	end
end

get '/stats' do
	if login?
		@user = User.first :email => session[:email]
		@tasks = @user.tasks
		@checks = @user.checks
		erb :stats
	else
		erb :index
	end
end

get "/signup" do
  erb :signup
end

post "/signup" do
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
			@errors = Array.new
			user.errors.each do |e|
				@errors.push e
			end
			erb :signup
		end
	end
end

get "/login" do
	erb :login
end

post "/login" do
  if User.first :email => params[:email]
    user = User.first :email => params[:email]
    if user.password == params[:password]
      session[:email] = params[:email]
      redirect "/"
    end
  end
  erb :error
end

get "/logout" do
  session[:email] = nil
  redirect "/"
end

get '/:id' do
	if login?
		@user = User.first :email => session[:email]
		@task = @user.tasks.get params[:id]
		erb :task
	else
		erb :index
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
		erb :index
	end
end

delete '/:id/delete' do
	if login?
		user = User.first :email => session[:email]
		t = user.tasks.get params[:id]
		t.checks.destroy
		t.destroy
	else
		erb :index
	end
end