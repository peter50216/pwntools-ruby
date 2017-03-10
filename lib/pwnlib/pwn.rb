# encoding: ASCII-8BIT

# require this file would also require all things in pwnlib, but would not
# pollute anything.

require 'pwnlib/asm'
require 'pwnlib/constants/constant'
require 'pwnlib/constants/constants'
require 'pwnlib/context'
require 'pwnlib/dynelf'
require 'pwnlib/reg_sort'
require 'pwnlib/shellcraft/shellcraft'

require 'pwnlib/util/cyclic'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/hexdump'
require 'pwnlib/util/lists'
require 'pwnlib/util/packing'

# include this module in a class to use all pwnlib functions in that class
# instance.
module Pwn
  include ::Pwnlib::Context

  include ::Pwnlib::Asm::ClassMethods
  include ::Pwnlib::Util::Cyclic::ClassMethods
  include ::Pwnlib::Util::Fiddling::ClassMethods
  include ::Pwnlib::Util::HexDump::ClassMethods
  include ::Pwnlib::Util::Packing::ClassMethods
  def shellcraft
    ::Pwnlib::Shellcraft.instance
  end
end
