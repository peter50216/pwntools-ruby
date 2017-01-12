# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class RetTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Root.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  ret\n", @shellcraft.ret)
      assert_equal("  xor eax, eax /* 0 */\n  ret\n", @shellcraft.ret(0))
      assert_equal(<<-'EOS', @shellcraft.ret(0x100000000))
  mov rax, 0x101010201010101 /* 4294967296 == 0x100000000 */
  push rax
  mov rax, 0x101010301010101
  xor [rsp], rax
  pop rax
  ret
      EOS
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      # should can use amd64.ret
      assert_equal(<<-'EOS', @shellcraft.amd64.ret(0x100000000))
  mov rax, 0x101010201010101 /* 4294967296 == 0x100000000 */
  push rax
  mov rax, 0x101010301010101
  xor [rsp], rax
  pop rax
  ret
      EOS
    end
  end
end
