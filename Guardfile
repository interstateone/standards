guard 'rspec', :notification => true, :version => 2 do
  watch(%r{^spec/.+_spec\.rb$}) { 'spec' }
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/(.+)\.rb$}) { 'spec' }
  watch('Rakefile') { 'spec' }
end