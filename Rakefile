require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb', 'test/**/*.rb']
  task.formatters = ['files']
end

task default: [:rubocop, :test]

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib'
  test.libs << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
