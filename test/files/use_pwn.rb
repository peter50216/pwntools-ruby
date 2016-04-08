# encoding: ASCII-8BIT
require 'pwn'

context[arch: 'amd64']

fail unless pack(1) == "\x01\0\0\0\0\0\0\0"
fail unless Pwnlib::Util::Fiddling.send(:context).object_id == context.object_id
fail unless Pwnlib::Context.context.object_id == context.object_id

# Make sure things aren't polluting Object
fail if (1.send(:context); true) rescue false
fail if ('1'.send(:context); true) rescue false

