require 'fileutils'
require 'pathname'
require 'tempfile'
require 'less'

namespace :requirejs do

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
Unable to find 'node' on the current path, required for precompilation
using the requirejs-ruby gem. To install node.js, see http://nodejs.org/
OS X Homebrew users can use 'brew install node'.
EOM
      exit 1
    end
  end

  namespace :precompile do
    task :all => ["requirejs:precompile:rjs",
                  "requirejs:precompile:less"]

    # Invoke another ruby process if we're called from inside
    # assets:precompile so we don't clobber the environment
    #
    # We depend on test_node here so we'll fail early and hard if node
    # isn't available.
    task :external => ["requirejs:test_node"] do
      Rake::Task["requirejs:precompile:all"].invoke
    end

    task :rjs do
      `cd public/js; node lib/r.js -o build.js`
      unless $?.success?
        raise RuntimeError, "js compilation with r.js failed."
      end
    end

    task :less do
      less = File.open('public/less/bootstrap.less', 'r').read
      parser = Less::Parser.new :paths => ['public/less/']
      tree = parser.parse less
      css = tree.to_css
      File.open('public/css/styles.css', 'w') {|f| f.write(css) }
    end
  end

  desc "Precompile r.js and less assets"
  task :precompile do
    invoke_or_reboot_rake_task "requirejs:precompile:all"
  end
end

task "assets:precompile" => ["requirejs:precompile:external"]
if ARGV[0] == "requirejs:precompile:all"
  task "assets:environment" => ["requirejs:precompile:disable_js_compressor"]
end
