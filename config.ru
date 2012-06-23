require './standards'
require './api'
require 'bowtie'

map "/bowtie" do
	BOWTIE_AUTH = {:user => ENV['BOWTIE_ADMIN'], :pass => ENV['BOWTIE_PASSWORD']}
	run Bowtie::Admin
end

map "/api" do
	run API
end

map '/' do
	run Standards
end