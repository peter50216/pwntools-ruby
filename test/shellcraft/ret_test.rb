# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class RetTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  ret\n", @shellcraft.ret)
      assert_equal("  mov rax, rdi\n  ret\n", @shellcraft.ret(:rdi))
      assert_equal("  xor eax, eax /* 0 */\n  ret\n", @shellcraft.ret(0))
      assert_equal(<<-'EOS', @shellcraft.ret(0x100000000))
  mov rax, 0x101010201010101
  push rax
  mov rax, 0x101010301010101
  xor [rsp], rax /* 0x100000000 == 0x101010201010101 ^ 0x101010301010101 */
  pop rax
  ret
      EOS
    end
  end
end
