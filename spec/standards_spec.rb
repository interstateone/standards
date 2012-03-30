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

	it 'should not be able to log in until confirmed' do
		@user.attributes = valid_user_attributes
		@user.save.should == true
		post '/login', {:email => @user.email, :password => valid_user_attributes['password']}
		session[:id].should == nil
	end
	it 'should only be able to be confirmed once'
	it 'should receive a confirmation email when created'
	it 'should not be confirmed unless the link has been visited'
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
	include UserSpecHelper

	before :each do
		user = User.new valid_user_attributes
		user.save
	end

	it 'should have a title' do
		get '/'
		last_response.body.include? "Standards"
	end
end

describe 'task pages' do
	it_should_behave_like "Standards"

	before :each do
		post "/login", {:email => "test@test.com", :password => "testtest123"}
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

# describe 'edit page' do
# 	it_should_behave_like 'Standards'

# 	it 'should list the tasks' do

# 	end
# end

# describe 'not logged in' do
# 	it_should_behave_like "Standards"

# 	it 'should flash an error' do
# 		get '/home'
# 		last_response.body.include? 'You must be logged in'
# 	end
# end