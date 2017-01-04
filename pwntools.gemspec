lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pwnlib/version'
require 'date'

Gem::Specification.new do |s|
  s.name          = 'pwntools'
  s.version       = ::Pwnlib::VERSION
  s.date          = Date.today.to_s
  s.summary       = 'pwntools'
  s.description   = <<-EOS
  Rewrite https://github.com/Gallopsled/pwntools in ruby.
  Implement useful/easy function first,
  try to be of ruby style and don't follow original pwntools everywhere.
  Would still try to have similar name whenever possible.
  EOS
  s.license       = 'MIT'
  s.authors       = ['peter50216@gmail.com']
  s.files         = Dir['lib/**/*.rb', 'lib/**/*.erb'] + %w(README.md Rakefile)
  s.test_files    = Dir['test/**/*']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.1.0'

  s.add_development_dependency 'pry', '~> 0.10'
  s.add_development_dependency 'rake', '~> 11.1'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.5'
  s.add_development_dependency 'rubocop', '~> 0.39'
end
