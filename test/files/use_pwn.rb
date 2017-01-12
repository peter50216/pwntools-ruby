# encoding: ASCII-8BIT

# Make sure we're using local copy for local testing.
$LOAD_PATH.unshift File.expand_path(File.join(__FILE__, '..', '..', '..', 'lib'))

require 'pwn'

context[arch: 'amd64']

raise 'pack fail' unless pack(1) == "\x01\0\0\0\0\0\0\0"
unless ::Pwnlib::Util::Fiddling.__send__(:context).object_id == context.object_id
  raise 'not unique context'
end
unless ::Pwnlib::Context.context.object_id == context.object_id
  raise 'not unique context'
end

# Make sure things aren't polluting Object
begin
  1.__send__(:context)
  raise 'context polluting Object.'
rescue NoMethodError
  puts 'good'
end

begin
  '1'.__send__(:context)
  raise 'context polluting Object.'
rescue NoMethodError
  puts 'good'
end

# Make sure we can use Util::xxx::yyy directly
raise 'pack fail' unless Util::Packing.pack(1) == "\x01\0\0\0\0\0\0\0"
