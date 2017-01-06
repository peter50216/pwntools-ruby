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
      assert_equal("  mov rax, 0x101010201010101 /* 4294967296 == 0x100000000 */\n  push rax\n  mov rax, 0x101010301010101\n  xor [rsp], rax\n  pop rax\n  ret\n",
                   Shellcraft.ret(0x100000000))
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      # should can use amd64.ret
      assert_equal("  mov rax, 0x101010201010101 /* 4294967296 == 0x100000000 */\n  push rax\n  mov rax, 0x101010301010101\n  xor [rsp], rax\n  pop rax\n  ret\n",
                   Shellcraft.amd64.ret(0x100000000))
    end
  end
end
