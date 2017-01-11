# encoding: ASCII-8BIT

# require this file would also require all things in pwnlib, but would not
# pollute anything.

require 'pwnlib/constants/constant'
require 'pwnlib/constants/constants'
require 'pwnlib/context'
require 'pwnlib/dynelf'
require 'pwnlib/util/cyclic'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/packing'

require 'pwnlib/reg_sort'

# include this module in a class to use all pwnlib functions in that class
# instance.
module Pwn
  include ::Pwnlib::Context

  include ::Pwnlib::Util::Packing::ClassMethod
  include ::Pwnlib::Util::Cyclic::ClassMethod
  include ::Pwnlib::Util::Fiddling::ClassMethod
end
