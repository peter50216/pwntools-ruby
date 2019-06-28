# encoding: ASCII-8BIT
# frozen_string_literal: true

# require this file would also require all things in pwnlib, but would not pollute anything.

require 'pwnlib/asm'
require 'pwnlib/constants/constant'
require 'pwnlib/constants/constants'
require 'pwnlib/context'
require 'pwnlib/dynelf'
require 'pwnlib/elf/elf'
require 'pwnlib/errors'
require 'pwnlib/logger'
require 'pwnlib/reg_sort'
require 'pwnlib/runner'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/tubes/process'
require 'pwnlib/tubes/serialtube'
require 'pwnlib/tubes/sock'
require 'pwnlib/ui'
require 'pwnlib/util/cyclic'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/getdents'
require 'pwnlib/util/hexdump'
require 'pwnlib/util/lists'
require 'pwnlib/util/packing'

# include this module in a class to use all pwnlib functions in that class instance.
module Pwn
  include ::Pwnlib::Asm
  include ::Pwnlib::Context
  include ::Pwnlib::Logger
  include ::Pwnlib::Runner
  include ::Pwnlib::UI
  include ::Pwnlib::Util::Cyclic
  include ::Pwnlib::Util::Fiddling
  include ::Pwnlib::Util::HexDump
  include ::Pwnlib::Util::Lists
  include ::Pwnlib::Util::Packing

  def shellcraft
    ::Pwnlib::Shellcraft::Shellcraft.instance
  end
end
