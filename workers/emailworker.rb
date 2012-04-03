class EmailWorker < IronWorker::Base

	merge_gem 'iron_worker'
	merge_gem 'pony'

	attr_accessor :username, :password, :to, :from, :subject, :body

	def run
		send_mail
	end

	def send_mail
		Pony.mail({
			:to => to,
			:from => from,
			:subject => subject,
			:via => :smtp,
			:via_options => {
				:address              => 'smtp.gmail.com',
				:port                 => '587',
				:enable_starttls_auto => true,
				:user_name            => username,
				:password             => password,
				:authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
				:domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
			},
			:html_body => body
		}) unless test?
	end
end