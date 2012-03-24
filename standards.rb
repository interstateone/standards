require 'bundler/setup'

Bundler.require(:default)

SITE_TITLE = "Standards"

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/standards.db")

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

get '/' do
	@tasks = Task.all
	@checks = Check.all
	erb :home
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