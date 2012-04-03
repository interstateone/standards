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
		{ :email => 'test@gmail.com',
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

	it 'should be invalid without a user'
	it 'should be invalid without a task'
	it 'should be invalid without a date'
end

shared_examples_for "Standards" do
	it 'should have a title' do
		get '/'
		last_response.body.include? "Standards"
	end
end

describe 'when logged in as a user' do
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
		last_response.body.include? "Add a task"
		@task = Task.create :title => 'Ride a bike', :user => @user
		get '/'
		last_response.body.include? "Ride a bike"
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
		get "/logout"
		follow_redirect!
	end

	it 'should not be able to add tasks' do
		get '/new'
		last_response.body.should_not include 'New task'
	end

	it 'should not be able to view a task' do
		@task = Task.create :title => 'Ride a bike', :user => @user
		get '/1/'
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

# describe 'task pages' do
# 	it_should_behave_like "Standards"
# 	include UserSpecHelper

# 	before :each do
# 		post "/login", valid_user_attributes
# 	end

# 	it 'should throw an error if its not a valid task id' do
# 		get '/23423423423423'
# 		last_response.body.include? "That task can't be found."
# 		# last_response.status.should be 404
# 	end

# 	it 'should load a task if its a valid task id' do
# 		test = Task.new :id => 1, :title => "Test task"
# 		test.save
# 		get '/1'
# 		last_response.body.include? "Test task"
# 	end
# end

# describe 'not logged in' do
# 	it_should_behave_like "Standards"

# 	it 'should flash an error' do
# 		get '/home'
# 		last_response.body.include? 'You must be logged in'
# 	end
# end