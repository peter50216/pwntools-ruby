# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class MovTest < MiniTest::Test
  include ::Pwnlib::Context

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("    xor eax, eax /* 0 */\n", ::Pwnlib::Shellcraft.mov('rax', 0))
      assert_equal("    push 9 /* mov eax, '\\n' */\n    pop rax\n    inc eax\n", ::Pwnlib::Shellcraft.mov('rax', 10))
      assert_equal("    xor ebx, ebx\n    mov bh, 0x100 >> 8\n", ::Pwnlib::Shellcraft.mov('ebx', 0x100))
      assert_equal("    mov edi, 0x1010201 /* 256 == 0x100 */\n    xor edi, 0x1010301\n", ::Pwnlib::Shellcraft.mov('rdi', 0x100))
      assert_equal("    push 0xffffffff\n    pop r15\n", ::Pwnlib::Shellcraft.mov('r15', 0xffffffff))
      assert_equal("    push -1\n    pop rsi\n", ::Pwnlib::Shellcraft.mov('rsi', -1))
      assert_equal("    mov esi, -1\n", ::Pwnlib::Shellcraft.mov('rsi', -1, stack_allowed: false))
      assert_equal("    movzx edi, ax\n", ::Pwnlib::Shellcraft.mov('rdi', 'ax'))
      assert_equal("    mov rdx, rbx\n", ::Pwnlib::Shellcraft.mov('rdx', 'rbx'))
    end
  end
end
