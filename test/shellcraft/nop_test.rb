# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class NopTest < MiniTest::Test
  include ::Pwnlib::Context
  Shellcraft = ::Pwnlib::Shellcraft

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  nop\n", Shellcraft.nop)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal("  nop\n", Shellcraft.nop)
    end
  end
end
