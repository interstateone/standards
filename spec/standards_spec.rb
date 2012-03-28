require_relative 'spec_helper.rb'

shared_examples_for "Standards" do
	before :each do
		user = User.new :email => "test@test.com", :password => "testtest123"
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
		post "/login", {:username => "test@test.com", :password => "testtest123"}
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

describe 'edit page' do
	it_should_behave_like 'Standards'

	it 'should list the tasks' do

	end
end

describe 'not logged in' do
	it_should_behave_like "Standards"

	it 'should flash an error' do
		get '/home'
		last_response.body.include? 'You must be logged in'
	end
end