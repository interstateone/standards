require 'bundler/setup'
Bundler.require()
require 'yaml'
require 'active_support/core_ext/time/zones'
require 'active_support/time_with_zone'
require 'active_support/core_ext/time/conversions'
require_relative 'workers/emailworker'
include Colorist

SITE_TITLE = "Standards"

configure :production do
	DataMapper.setup(:default, ENV['DATABASE_URL'])
	use Rack::Session::Cookie, :expire_after => 2592000
	set :session_secret, ENV['SESSION_KEY']
end

configure :development do
	yaml = YAML.load_file("config.yaml")
	yaml.each_pair do |key, value|
		set(key.to_sym, value)
	end

	DataMapper.setup(:default, "postgres://" + settings.db_user + ":" + settings.db_password + "@" + settings.db_host + "/" + settings.db_name)
	use Rack::Session::Cookie, :expire_after => 2592000
	set :session_secret, settings.session_secret
end

IronWorker.configure do |config|
	config.token = ENV['IRON_WORKER_TOKEN']
	config.project_id = ENV['IRON_WORKER_PROJECT_ID']
end

require './models/init'
require './helpers/app_helpers'
require './routes/app'