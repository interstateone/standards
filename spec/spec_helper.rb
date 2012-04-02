Bundler.require(:default, :test)

set :environment, :test

configure :test do
	DataMapper.setup(:default, "sqlite::memory:")
	REDIS = Redis.new()
	use Rack::Session::Cookie
end

require_relative '../standards.rb'

module RSpecMixin
  include Rack::Test::Methods
  def app
  	Sinatra::Application
  end
  set :views, settings.root + '/../views'
end

# Reset the database for each test
Rspec.configure do |config|
	config.before(:each) { DataMapper.auto_migrate! }
	config.include RSpecMixin
end