require 'bundler/setup'
Bundler.require()
require 'active_support/core_ext/time/zones'
require 'active_support/time_with_zone'
require 'active_support/core_ext/time/conversions'
require 'fileutils'
require 'pathname'
require 'tempfile'

if (ENV['RAKE_ENV'] == 'production')
  DataMapper.setup(:default, ENV['DATABASE_URL'])
end

if (ENV['RAKE_ENV'] == 'development')
  yaml = YAML.load_file("config.yaml")
  yaml.each_pair do |key, value|
    set(key.to_sym, value)
  end

  DataMapper.setup(:default, "postgres://" + settings.db_user + ":" + settings.db_password + "@" + settings.db_host + "/" + settings.db_name)
end

require_relative 'app/models/init'

namespace :assets do

  # From Rails 3 assets.rake; we have the same problem:
  #
  # We are currently running with no explicit bundler group
  # and/or no explicit environment - we have to reinvoke rake to
  # execute this task.
  def invoke_or_reboot_rake_task(task)
    Rake::Task[task].invoke
  end

  task :test_node do
    begin
      `node -v`
    rescue Errno::ENOENT
      STDERR.puts <<-EOM
Unable to find 'node' on the current path.
EOM
      exit 1
    end
  end

  namespace :precompile do
    task :all => ["assets:precompile:rjs",
                  "assets:precompile:less"]

    # Invoke another ruby process if we're called from inside
    # assets:precompile so we don't clobber the environment
    #
    # We depend on test_node here so we'll fail early and hard if node
    # isn't available.
    task :external => ["assets:test_node"] do
      Rake::Task["assets:precompile:all"].invoke
    end

    task :rjs do
      `cd public/js; ../../bin/node lib/r.js -o build.js`
      unless $?.success?
        raise RuntimeError, "js compilation with r.js failed."
      end
    end

    task :less do
      less = File.open('public/less/bootstrap.less', 'r').read
      parser = Less::Parser.new :paths => ['public/less/']
      tree = parser.parse less
      css = tree.to_css
      Dir.mkdir 'public/css/'
      File.open('public/css/styles.css', 'w') {|f| f.write(css) }
    end
  end

  desc "Precompile r.js and less assets"
  task :precompile do
    invoke_or_reboot_rake_task "assets:precompile:all"
  end
end
task "assets:precompile" => ["assets:precompile:external"]

namespace :reminders do
  task :daily do
    server_time = Time.now
    User.all.each do |user|
      next unless user.daily_reminder_permission
      user_time = server_time.in_time_zone(user.timezone)
      puts "checking #{user.id}"
      unless (user.check_today?)
        puts "no checks for #{user.id}"
        if (user_time.hour === user.daily_reminder_time) || ((user_time.hour === user.daily_reminder_time - 1) && (user_time.min.between?(55,60)))
          puts "sending email to #{user.id}"
          if ENV['RACK_ENV'] === 'production' || ENV['RACK_ENV'] === 'development'
            RestClient.post "https://api:key-2oe0h2j0yx214p4vnz7wyv9ef1c5fdk2"\
            "@api.mailgun.net/v2/app4624790.mailgun.org/messages",
            :from => "Standards <standards@brandonevans.ca>",
            :to => user.email,
            :subject => "Today's Reminder",
            :text => "Remember to check off your standards for the day!"
          end
        end
      end
    end
  end
end