Bundler.require(:default, :test)
set :environment, :test
set :delivery_method, :test
require_relative '../standards.rb'

module RSpecMixin
  include Rack::Test::Methods
  def app
  	Sinatra::Application
  end
end

# Reset the database for each test
Rspec.configure do |config|
	config.before(:each) { DataMapper.auto_migrate! }
	config.include RSpecMixin
end