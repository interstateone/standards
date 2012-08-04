guard 'rspec', :notification => true, :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }
  watch('app/standards.rb') { "standards_spec.rb" }
  watch('Rakefile') { "rake_spec.rb" }
end