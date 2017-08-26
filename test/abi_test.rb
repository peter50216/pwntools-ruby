# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/abi'
require 'pwnlib/context'

class AbiTest < MiniTest::Test
  include ::Pwnlib::Context
  ABI = ::Pwnlib::ABI

  def test_default
    context.local(arch: 'i386', os: 'linux') { assert_same ABI::DEFAULT[[32, 'i386', 'linux']], ABI::ABI.default }
    context.local(arch: 'amd64', os: 'linux') { assert_same ABI::DEFAULT[[64, 'amd64', 'linux']], ABI::ABI.default }
  end

  def test_syscall
    context.local(arch: 'i386', os: 'linux') { assert_same ABI::SYSCALL[[32, 'i386', 'linux']], ABI::ABI.syscall }
    context.local(arch: 'amd64', os: 'linux') { assert_same ABI::SYSCALL[[64, 'amd64', 'linux']], ABI::ABI.syscall }
  end
end
