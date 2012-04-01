require 'resque/server'
require './standards'
require 'bowtie'

map "/admin" do
	BOWTIE_AUTH = {:user => ENV['BOWTIE_ADMIN'], :pass => ENV['BOWTIE_PASSWORD']}
	run Bowtie::Admin
end

map "/resque" do
	run Resque::Server.new
end

map '/' do
	run Sinatra::Application
end