lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'date'

require 'pwnlib/version'

Gem::Specification.new do |s|
  s.name          = 'pwntools'
  s.version       = ::Pwnlib::VERSION
  s.date          = Date.today.to_s
  s.summary       = 'pwntools'
  s.description   = <<-EOS
  Rewrite https://github.com/Gallopsled/pwntools in ruby.
  Implement useful/easy functions first,
  try to be of ruby style and don't follow original pwntools everywhere.
  Would still try to have similar name whenever possible.
  EOS
  s.license       = 'MIT'
  s.authors       = ['peter50216@gmail.com', 'david942j@gmail.com', 'hanhan0912@gmail.com']
  s.files         = Dir['lib/**/*.rb'] + %w(README.md Rakefile)
  s.test_files    = Dir['test/**/*']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.1.0'

  s.add_runtime_dependency 'rainbow', '~> 2.2'
  s.add_runtime_dependency 'elftools', '~> 1.0.1'
  s.add_runtime_dependency 'dentaku', '~> 2.0.11'

  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.6'
  # TODO(david942j): check why ruby crash during testing if upgrade minitest to 5.10.2/3
  s.add_development_dependency 'minitest', '= 5.10.1'
  s.add_development_dependency 'pry', '~> 0.10'
  s.add_development_dependency 'rake', '~> 12.1'
  s.add_development_dependency 'rubocop', '~> 0.49'
  s.add_development_dependency 'simplecov', '~> 0.15'
  s.add_development_dependency 'tty-platform', '~> 0.1'
  s.add_development_dependency 'yard', '~> 0.9'
end
