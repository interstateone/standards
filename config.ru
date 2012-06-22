require './standards'
require 'bowtie'

map "/bowtie" do
	BOWTIE_AUTH = {:user => ENV['BOWTIE_ADMIN'], :pass => ENV['BOWTIE_PASSWORD']}
	run Bowtie::Admin
end

map "/api" do
	run API::Application
end

map '/' do
	run Sinatra::Application
end