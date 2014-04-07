require "bundler/gem_tasks"

task :default => :test
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end


# bundle exec rake console
# LS::BrowseService.host = 'http://browse-service.browse-service.qa.livingsocial.net/'
# LS::BrowseService::Client.new.get_category('washington-d-c','food-deals')
desc "start a console with the gem loaded"
task :console do
  sh "irb -rubygems -I lib -r ls/browse-service-client.rb"
end
