# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/context'
require 'pwnlib/abi'

class AbiTest < MiniTest::Test
  include ::Pwnlib::Context
  ABI = ::Pwnlib::ABI

  def test_default
    context.local(arch: 'i386', os: 'linux') { assert_same ABI::LINUX_I386, ABI::ABI.default }
    context.local(arch: 'amd64', os: 'linux') { assert_same ABI::LINUX_AMD64, ABI::ABI.default }
  end

  def test_syscall
    context.local(arch: 'i386', os: 'linux') { assert_same ABI::LINUX_I386_SYSCALL, ABI::ABI.syscall }
    context.local(arch: 'amd64', os: 'linux') { assert_same ABI::LINUX_AMD64_SYSCALL, ABI::ABI.syscall }
  end

  def test_returns
    assert(ABI::LINUX_AMD64_SYSCALL.returns)
  end
end
