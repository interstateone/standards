require_relative 'spec_helper.rb'

class Hash
	def except(*blacklist)
		reject {|key, value| blacklist.include?(key) }
	end

	def only(*whitelist)
		reject {|key, value| !whitelist.include?(key) }
	end
end

module UserSpecHelper
	def valid_user_attributes
		{ :email => 'Test@gmail.com',
		:name => 'Mike',
		:password => 'Tes7yasdf' }
	end
end

describe 'A user' do
	include UserSpecHelper

	before do
		@user = User.new
	end

	it 'should be invalid without a name' do
		@user.attributes = valid_user_attributes.except(:name)
		@user.save.should == false
		@user.name = valid_user_attributes[:name]
		@user.save.should == true
	end

	it 'should be invalid without a password' do
		@user.attributes = valid_user_attributes.except(:password)
		@user.save.should == false
		@user.password = valid_user_attributes[:password]
		@user.save.should == true
	end

	it 'should be invalid with a password less than 8 characters long' do
		@user.attributes = valid_user_attributes.except(:password)
		@user.save.should == false
		@user.password = "aaa"
		@user.save.should == false
		@user.password = "asdfghjk4"
		@user.save.should == true
	end

	it 'should be invalid with a password that doesnt contain a number' do
		@user.attributes = valid_user_attributes.except(:password)
		@user.save.should == false
		@user.password = "asdfghjk"
		@user.save.should == false
		@user.password = "asdfghjk4"
		@user.save.should == true
	end
end

describe 'A task' do
	include UserSpecHelper

	before do
		@user = User.new valid_user_attributes
		@task = Task.new
	end

	it 'should be invalid without a user' do
		@task.title = 'Ride a bike'
		@task.save.should == false
		@task.user = @user
		@task.save.should == true
	end

	it 'should be invalid without a title' do
		@task.user = @user
		@task.save.should == false
		@task.title = 'Ride a bike'
		@task.save.should == true
	end
end

describe 'A check' do
	include UserSpecHelper

	before do
		@user = User.new valid_user_attributes
		@task = Task.new :title => 'Ride a bike', :user => @user
	end
end

shared_examples_for "Standards" do
	it 'should have a title' do
		get '/'
		last_response.body.include? "Standards"
	end
end

describe 'When signing up' do
	include UserSpecHelper

	before :each do
		@user = User.create valid_user_attributes
	end

	it 'existing users should be logged in' do
		post "/signup", valid_user_attributes
		last_response.body.include? valid_user_attributes[:name]
		get '/logout'
		post '/login', { :email => valid_user_attributes[:email].upcase, :password => valid_user_attributes[:password] }
		last_response.body.include? valid_user_attributes[:name]
	end

	it 'new users should be created' do
		post "/signup", { :name => 'newtest', :email => 'newtest@gmail.com', :password => 'abcdefghijk' }
		last_response.body.include? 'newtest'
	end
end

describe 'When logging in' do
	include UserSpecHelper

	it 'emails should be case-insensitive' do
		@user = User.create valid_user_attributes
		post '/login', { :email => valid_user_attributes[:email], :password => valid_user_attributes[:password] }
		last_response.body.should_not include "Email and password don't match."
		get '/logout'
		post '/login', { :email => valid_user_attributes[:email].upcase, :password => valid_user_attributes[:password] }
		last_response.body.should_not include "Email and password don't match."
	end
end

describe 'When logged in as a user' do
	it_should_behave_like 'Standards'
	include UserSpecHelper

	before :each do
		@user = User.new valid_user_attributes
		@user.save
		post "/login", valid_user_attributes
	end

	it 'should show welcome message or list tasks' do
		get '/'
		last_response.body.include? "Add a task"
	end

	it 'should allow making a new task' do
		get '/'
		last_response.body.include? "Add it!"
		@task = Task.create :title => 'Ride a bike', :user => @user
		@task.errors.should be_empty
	end

	it 'should allow deleting a task' do
		@task = Task.create :title => 'Ride a bike', :user => @user
		delete '/1/'
		# This is an AJAX request...
		last_response.body.include? 'Task deleted'
	end
end

describe 'Unauthorized users' do
	it_should_behave_like 'Standards'
	include UserSpecHelper

	before :each do
		@user = User.new valid_user_attributes
		@user.save
		@task = Task.create :title => 'Ride a bike', :user => @user
		get "/logout"
		follow_redirect!
	end

	it 'should not be able to add tasks' do
		get '/new'
		last_response.body.should_not include 'Add it'
	end

	it 'should not be able to view a task' do
		get '/1'
		last_response.body.should_not include 'Ride a bike'
	end

	it 'should not be able to view stats' do
		get '/stats'
		last_response.body.should_not include 'Stats'
	end

	it 'should not be able to view settings' do
		get '/settings'
		last_response.body.should_not include 'Settings'
	end
end

describe 'task pages' do
	it_should_behave_like "Standards"
	include UserSpecHelper

	before :each do
		post "/login", valid_user_attributes
	end

	it 'should throw an error if its not a valid task id' do
		get '/23423423423423'
		last_response.body.include? "That task can't be found."
		# last_response.status.should be 404
	end

	it 'should load a task if its a valid task id' do
		test = Task.new :id => 1, :title => "Test task"
		test.save
		get '/1'
		last_response.body.include? "Test task"
	end
end

describe 'not logged in' do
	it_should_behave_like "Standards"

	it 'should flash an error' do
		get '/home'
		last_response.body.include? 'You must be logged in'
	end
end