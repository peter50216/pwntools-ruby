# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class MovTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Root.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  xor eax, eax /* 0 */\n", @shellcraft.mov('rax', 0))
      assert_equal("  /* moving rax into rax, but this is a no-op */\n", @shellcraft.mov('rax', 'rax'))
      assert_equal("  push 9 /* mov eax, '\\n' */\n  pop rax\n  inc eax\n", @shellcraft.mov('rax', 10))
      assert_equal("  xor eax, eax\n  mov al, 0xc0\n", @shellcraft.mov('rax', 0xc0))
      assert_equal("  xor eax, eax\n  mov ax, 0xc0c0\n", @shellcraft.mov('rax', 0xc0c0))
      assert_equal("  xor ebx, ebx\n  mov bh, 0x100 >> 8\n", @shellcraft.mov('ebx', 0x100))
      assert_equal("  mov edi, 0x1010201 /* 256 == 0x100 */\n  xor edi, 0x1010301\n", @shellcraft.mov('rdi', 0x100))
      # FIXME(david942j): bug of python-pwntools!
      assert_equal("  push 0xffffffff\n  pop r15\n", @shellcraft.mov('r15', 0xffffffff))
      assert_equal("  push -1\n  pop rsi\n", @shellcraft.mov('rsi', -1))
      assert_equal("  mov esi, -1\n", @shellcraft.mov('rsi', -1, stack_allowed: false))
      assert_equal("  movzx edi, ax\n", @shellcraft.mov('rdi', 'ax'))
      assert_equal("  mov rdx, rbx\n", @shellcraft.mov('rdx', 'rbx'))
      assert_equal("  xor eax, eax /* (SYS_read) */\n", @shellcraft.mov('rax', 'SYS_read'))
      assert_equal("  push (SYS_write) /* 1 */\n  pop rax\n", @shellcraft.mov('eax', 'SYS_write'))
      assert_equal("  xor ax, ax\n  mov al, (SYS_write) /* 1 */\n", @shellcraft.mov('ax', 'SYS_write'))
      assert_equal("  /* moving ax into al, but this is a no-op */\n", @shellcraft.mov('al', 'ax'))
      assert_equal("  mov rax, 0x101010101010101 /* 76750323967 == 0x11dead00ff */\n  push rax\n  mov rax, 0x1010110dfac01fe\n  xor [rsp], rax\n  pop rax\n", @shellcraft.mov('rax', 0x11dead00ff))

      # raises
      err = assert_raises(ArgumentError) { @shellcraft.mov('eax', 'rdx') }
      assert_equal('cannot mov eax, rdx: dest is smaller than src', err.message)
      err = assert_raises(ArgumentError) { @shellcraft.mov('rcx', 0x7f00000000, stack_allowed: false) }
      assert_equal('Cannot put 0x7f00000000 into \'rcx\' without using stack.', err.message)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      # still can use amd64.mov
      assert_equal("  mov rdx, rbx\n", @shellcraft.amd64.mov('rdx', 'rbx'))
    end
  end
end
