Gem::Specification.new do |s|
  s.name        = 'pwntools'
  s.version     = '0.0.0'
  s.date        = '2016-03-23'
  s.summary     = 'pwntools'
  s.description = <<-EOS
  Rewrite https://github.com/Gallopsled/pwntools in ruby.
  Implement useful/easy function first,
  try to be of ruby style and don't follow original pwntools everywhere.
  Would still try to have similar name whenever possible.
  EOS
  s.license     = 'MIT'
  s.authors     = ['peter50216@gmail.com']
  s.files       = Dir['lib/**/*.rb']

  s.required_ruby_version = '>= 2.0'

  s.add_development_dependency 'pry', '~> 0.10.1'
end
