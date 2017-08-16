# encoding: ASCII-8BIT

# require this file for easy exploit development, but would pollute main Object and some built-in objects. (String,
# Integer, ...)

require 'pwnlib/pwn'

require 'pwnlib/ext/string'
require 'pwnlib/ext/integer'
require 'pwnlib/ext/array'

extend Pwn

include Pwnlib

# XXX(david942j): include here because module ELF and class ELF have same name..
include ::Pwnlib::ELF

# Small "fix" for irb context problem.
# irb defines main.context for IRB::Context, which overrides our Pwnlib::Context. :(
# Since our "context" should be more important for someone requiring 'pwn', and the IRB::Context can still be accessible
# from irb_context, we should be fine removing context.
class << self
  remove_method(:context) if method_defined?(:context)
end
