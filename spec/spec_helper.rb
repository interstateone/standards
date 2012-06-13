Bundler.require(:default, :test)

set :environment, :test

configure :test do
	yaml = YAML.load_file("config.yaml")
	yaml.each_pair do |key, value|
		set(key.to_sym, value)
	end

	DataMapper.setup(:default, "sqlite::memory:")
	use Rack::Session::Cookie
	set :session_secret, settings.session_secret
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