require 'fileutils'
require 'pathname'

require 'bundler/gem_tasks'
require 'rainbow'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'yard'

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb', 'test/**/*.rb']
end

task default: %i(install_git_hooks rubocop test doc)

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib'
  test.libs << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

YARD::Rake::YardocTask.new(:doc)

task :install_git_hooks do
  hooks = %w(pre-push)
  git_hook_dir = Pathname.new('.git/hooks/')
  hook_dir = Pathname.new('git-hooks/')
  hooks.each do |hook|
    src = hook_dir + hook
    target = git_hook_dir + hook
    next if target.symlink? && (target.dirname + target.readlink).realpath == src.realpath
    puts "Installing git hook #{hook}..."
    target.unlink if target.exist? || target.symlink?
    target.make_symlink(src.relative_path_from(target.dirname))
  end
  git_version = `git version`[/\Agit version (.*)\Z/, 1]
  if Gem::Version.new(git_version) < Gem::Version.new('1.8.2')
    puts Rainbow("Your git is older than 1.8.2, and doesn't support pre-push hook...").bright.red
    puts Rainbow('Please make sure test passed before pushing!!!!!!').bright.red
  end
end
