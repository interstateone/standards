require './standards'
require 'bowtie'

map '/standards.manifest' do
	run Rack::File.new 'standards.manifest'
end

map "/admin" do
	BOWTIE_AUTH = {:user => ENV['BOWTIE_ADMIN'], :pass => ENV['BOWTIE_PASSWORD']}
	run Bowtie::Admin
end

map '/' do
	run Sinatra::Application
end