require 'bundler/setup'
Bundler.require(:default)

SITE_TITLE = "Standards"

set :environment, :development

use Rack::Session::Cookie, :expire_after => 2592000
set :session_secret, ENV['SESSION_KEY'] || settings.session_secret

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://" + settings.db_user + ":" + settings.db_password + "@" + settings.db_host + "/" + settings.db_name)

# Configure test database
configure :test do
	DataMapper.setup(:default, "sqlite::memory:")
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
	property :confirmation_key, String, :default => lambda { |r,p| Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..10] }

	timestamps :on

	validates_presence_of :name
	validates_presence_of :email
	validates_uniqueness_of :email
	validates_presence_of :hashed_password, :message => "Password must be at least 8 characters with one number."

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

helpers do
	def logged_in?
		!!session[:id]
	end

	def current_user
		if session[:id]
			User.get session[:id]
		else
			nil
		end
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

	def send_confirmation_email(user)
		@user = user
		@url = ENV['CONFIRMATION_CALLBACK_URL'] || settings.confirmation_callback_url
		Pony.mail({
			:to => settings.email_target || user.email,
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
		})
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

# post '/' do
# 	login_required
# 	@user = User.first :email => session[:email]
# 	@task = Task.new
# 	@task.title = params[:tasktitle]
# 	@task.purpose = params[:taskpurpose]
# 	@task.user = @user
# 	@task.save

# 	erb :task_row_short, :layout => false
# end

# get '/edit' do
# 	login_required
# 	@user = current_user
# 	@tasks = @user.tasks
# 	erb :edit
# end

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
	if logged_in?
		@user = current_user
		@tasks = @user.tasks
		@checks = @user.checks
		erb :stats
	else
		erb :index
	end
end

get "/signup/?" do
  erb :signup
end

post "/signup/?" do
	# Validate the fields first
	# Don't worry about existing emails, we'll handle that later
	if !valid_email? params[:email]
		flash.now[:error] = "Please enter a valid email address."
		erb :signup
	else
		# Try creating a new user
		user = User.new
		user.name = params[:name]
		user.email = params[:email]
		user.password = params[:password]
		if user.save
			# Flash confirmation info and redirect
			send_confirmation_email user
			flash[:notice] = "You've been sent a confirmation email to the address you provided, click the link inside to get started."
			redirect "/"
		else
			user.errors.each do |e|
				flash.now[:error] = e
			end
			erb :signup
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
		flash.now[:error] = "Please enter an email address."
		erb :login
	else

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

delete '/:id/delete' do
	login_required
	user = current_user
	task = user.tasks.get params[:id]
	task.checks.destroy
	task.destroy

	flash[:notice] = "Task deleted."
	true
end

not_found do
	status 404
end

error do
	status 500
end