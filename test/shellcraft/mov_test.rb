# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class MovTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  xor eax, eax /* 0 */\n", @shellcraft.mov('rax', 0))
      assert_equal("  /* moving rax into rax, but this is a no-op */\n", @shellcraft.mov('rax', 'rax'))
      assert_equal("  push 9 /* mov eax, '\\n' */\n  pop rax\n  inc eax\n", @shellcraft.mov('rax', 10))
      assert_equal("  xor eax, eax\n  mov al, 0xc0\n", @shellcraft.mov('rax', 0xc0))
      assert_equal("  xor eax, eax\n  mov ax, 0xc0c0\n", @shellcraft.mov('rax', 0xc0c0))
      assert_equal("  xor ebx, ebx\n  mov bh, 0x100 >> 8\n", @shellcraft.mov('ebx', 0x100))
      assert_equal(<<-'EOS', @shellcraft.mov('rdi', 0x100))
  mov edi, 0x1010201
  xor edi, 0x1010301 /* 0x100 == 0x1010201 ^ 0x1010301 */
      EOS
      assert_equal("  mov r15d, 0xffffffff\n", @shellcraft.mov('r15', 0xffffffff))
      assert_equal("  push -1\n  pop rsi\n", @shellcraft.mov('rsi', -1))
      assert_equal("  mov esi, -1\n", @shellcraft.mov('rsi', -1, stack_allowed: false))
      assert_equal("  movzx edi, ax\n", @shellcraft.mov('rdi', 'ax'))
      assert_equal("  mov rdx, rbx\n", @shellcraft.mov('rdx', 'rbx'))
      assert_equal("  xor eax, eax /* (SYS_read) */\n", @shellcraft.mov('rax', 'SYS_read'))
      assert_equal("  push 1 /* (SYS_write) */\n  pop rax\n", @shellcraft.mov('eax', 'SYS_write'))
      assert_equal("  xor ax, ax\n  mov al, 1 /* (SYS_write) */\n", @shellcraft.mov('ax', 'SYS_write'))
      assert_equal("  /* moving ax into al, but this is a no-op */\n", @shellcraft.mov('al', 'ax'))
      assert_equal(<<-'EOS', @shellcraft.mov('rax', 0x11dead00ff))
  mov rax, 0x101010101010101
  push rax
  mov rax, 0x1010110dfac01fe
  xor [rsp], rax /* 0x11dead00ff == 0x101010101010101 ^ 0x1010110dfac01fe */
  pop rax
      EOS
      # raises
      err = assert_raises(ArgumentError) { @shellcraft.mov('eax', 'rdx') }
      assert_equal('cannot mov eax, rdx: dst is smaller than src', err.message)
      err = assert_raises(ArgumentError) { @shellcraft.mov('rcx', 0x7f00000000, stack_allowed: false) }
      assert_equal('Cannot put 0x7f00000000 into \'rcx\' without using stack.', err.message)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal("  mov eax, ebx\n", @shellcraft.mov('eax', 'ebx'))
      assert_equal("  xor eax, eax /* 0 */\n", @shellcraft.mov('eax', 0))
      assert_equal("  xor ax, ax /* 0 */\n", @shellcraft.mov('ax', 0))
      assert_equal("  xor ax, ax\n  mov al, 0x11\n", @shellcraft.mov('ax', 17))
      assert_equal(<<-EOS, @shellcraft.mov('edi', 10))
  push 9 /* mov edi, '\\n' */
  pop edi
  inc edi
      EOS
      assert_equal("  /* moving ax into al, but this is a no-op */\n", @shellcraft.mov('al', 'ax'))
      assert_equal("  /* moving esp into esp, but this is a no-op */\n", @shellcraft.mov('esp', 'esp'))
      assert_equal("  movzx ax, bl\n", @shellcraft.mov('ax', 'bl'))
      assert_equal("  push 1\n  pop eax\n", @shellcraft.mov('eax', 1))
      assert_equal("  xor eax, eax\n  mov al, 1\n", @shellcraft.mov('eax', 1, stack_allowed: false))
      assert_equal("  mov eax, 0xdeadbeaf\n", @shellcraft.mov('eax', 0xdeadbeaf))
      assert_equal("  mov eax, -0xdead00ff\n  neg eax\n", @shellcraft.mov('eax', 0xdead00ff))
      assert_equal("  xor eax, eax\n  mov al, 0xc0\n", @shellcraft.mov('eax', 0xc0))
      assert_equal("  mov edi, -0xc0\n  neg edi\n", @shellcraft.mov('edi', 0xc0))
      assert_equal("  xor eax, eax\n  mov ah, 0xc000 >> 8\n", @shellcraft.mov('eax', 0xc000))
      assert_equal(<<-EOS, @shellcraft.mov('eax', 0xffc000))
  mov eax, 0x1010101
  xor eax, 0x1fec101 /* 0xffc000 == 0x1010101 ^ 0x1fec101 */
      EOS
      assert_equal(<<-EOS, @shellcraft.mov('edi', 0xc000))
  mov edi, (-1) ^ 0xc000
  not edi
      EOS
      assert_equal(<<-EOS, @shellcraft.mov('edi', 0xf500))
  mov edi, 0x1010101
  xor edi, 0x101f401 /* 0xf500 == 0x1010101 ^ 0x101f401 */
      EOS
      assert_equal("  xor eax, eax\n  mov ax, 0xc0c0\n", @shellcraft.mov('eax', 0xc0c0))
      assert_equal(<<-EOS, @shellcraft.mov('eax', 'SYS_execve'))
  push 0xb /* (SYS_execve) */
  pop eax
      EOS
      assert_equal(<<-EOS, @shellcraft.mov('eax', 'PROT_READ | PROT_WRITE | PROT_EXEC'))
  push 7 /* (PROT_READ | PROT_WRITE | PROT_EXEC) */
  pop eax
      EOS
      # raises
      err = assert_raises(ArgumentError) { @shellcraft.mov('ax', 'ebx') }
      assert_equal('cannot mov ax, ebx: dst is smaller than src', err.message)
    end
  end
end
