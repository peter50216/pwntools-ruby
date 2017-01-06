# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class RetTest < MiniTest::Test
  include ::Pwnlib::Context
  Shellcraft = ::Pwnlib::Shellcraft

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  ret\n", Shellcraft.ret)
      assert_equal("  xor eax, eax /* 0 */\n  ret\n", Shellcraft.ret(0))
      assert_equal("  mov eax, 0x1010101 /* 12345678 == 0xbc614e */\n  xor eax, 0x1bd604f\n  ret\n", Shellcraft.ret(12_345_678))
    end
  end
end
