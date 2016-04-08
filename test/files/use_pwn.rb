# encoding: ASCII-8BIT
require 'pwn'

context[arch: 'amd64']

raise 'pack fail' unless pack(1) == "\x01\0\0\0\0\0\0\0"
unless Pwnlib::Util::Fiddling.send(:context).object_id == context.object_id
  raise 'not unique context'
end
unless Pwnlib::Context.context.object_id == context.object_id
  raise 'not unique context'
end

# Make sure things aren't polluting Object
begin
  1.send(:context)
  raise 'context polluting Object.'
rescue NoMethodError
  puts 'good'
end

begin
  '1'.send(:context)
  raise 'context polluting Object.'
rescue NoMethodError
  puts 'good'
end
