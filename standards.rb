require 'bundler/setup'
Bundler.require(:default)

SITE_TITLE = "Standards"
enable :sessions

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/standards.db")

class Task
	include DataMapper::Resource

	has n, :checks

	property :id, Serial
	property :title, Text, :required => true
	property :date_created, Date
end

class Check
	include DataMapper::Resource

	belongs_to :task

	property :id, Serial
	property :date, Date
end

DataMapper.finalize.auto_upgrade!

helpers do
	def login?
		if session[:username].nil?
			return false
		else
			return true
		end
	end

	def username
		return session[:username]
	end
end

get '/' do
	if login?
		@tasks = Task.all
		@checks = Check.all
		erb :home
	else
		erb :index
	end
end

post '/' do
	@task = Task.new
	@task.title = params[:tasktitle]
	@task.date_created = Date.today
	@task.save

	erb :task_row_short, :layout => false
end

get '/edit' do
	@tasks = Task.all
	erb :edit
end

get '/stats' do
	@tasks = Task.all
	@checks = Check.all
	erb :stats
end

get "/signup" do
  erb :signup
end

post "/signup" do
  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

  #ideally this would be saved into a database, hash used just for sample
  userTable[params[:username]] = {
    :salt => password_salt,
    :passwordhash => password_hash
  }

  session[:username] = params[:username]
  redirect "/"
end

post "/login" do
  if userTable.has_key?(params[:username])
    user = userTable[params[:username]]
    if user[:passwordhash] == BCrypt::Engine.hash_secret(params[:password], user[:salt])
      session[:username] = params[:username]
      redirect "/"
    end
  end
  erb :error
end

get "/logout" do
  session[:username] = nil
  redirect "/"
end

get '/:id' do
	@task = Task.get params[:id]
	erb :task
end

post '/:id/:date/complete' do
	t = Task.get params[:id]
	if t.checks(:date => params[:date]).count > 0
		c = t.checks :date => params[:date]
		c.destroy
	else
		c = Check.new
		c.date = params[:date]
		c.task = t
		c.save
		t.save
	end
end

delete '/:id/delete' do
	t = Task.get params[:id]
	t.checks.destroy
	t.destroy
end