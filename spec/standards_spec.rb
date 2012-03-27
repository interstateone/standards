require_relative '../standards.rb'
require 'rack/test'

set :environment, :test

def app
	Sinatra::Application
end

describe "Standards" do
	include Rack::Test::Methods

	it 'should load the home page' do
		get '/'
		last_response.should be_ok
	end

	describe 'error pages' do
		it 'should load an error with 404 status if not a task' do
			get '/asdasdasd'
			last_response.body.include? "Standards"
			last_response.body.include? "That task can't be found."
			last_response.status.should be 404
		end
	end
end