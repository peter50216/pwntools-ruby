# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class OpenTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.open('/etc/passwd'))
  /* push "/etc/passwd\x00" */
  push 0x1010101 ^ 0x647773
  xor dword ptr [rsp], 0x1010101
  mov rax, 0x7361702f6374652f
  push rax
  /* call open("rsp", "O_RDONLY", 0) */
  push 2 /* (SYS_open) */
  pop rax
  mov rdi, rsp
  xor esi, esi /* (O_RDONLY) */
  cdq /* rdx=0 */
  syscall
      EOS

      assert_equal(<<-'EOS', @shellcraft.open('/etc/passwd', 0x40, 0o750)) # O_CREAT = 0x40
  /* push "/etc/passwd\x00" */
  push 0x1010101 ^ 0x647773
  xor dword ptr [rsp], 0x1010101
  mov rax, 0x7361702f6374652f
  push rax
  /* call open("rsp", 64, 488) */
  push 2 /* (SYS_open) */
  pop rax
  mov rdi, rsp
  push 0x40
  pop rsi
  xor edx, edx
  mov dx, 0x1e8
  syscall
      EOS
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal(<<-'EOS', @shellcraft.open('/etc/passwd'))
  /* push "/etc/passwd\x00" */
  push 0x1010101
  xor dword ptr [esp], 0x1657672 /* 0x1010101 ^ 0x647773 */
  push 0x7361702f
  push 0x6374652f
  /* call open("esp", "O_RDONLY", 0) */
  push 5 /* (SYS_open) */
  pop eax
  mov ebx, esp
  xor ecx, ecx /* (O_RDONLY) */
  cdq /* edx=0 */
  int 0x80
      EOS

      assert_equal(<<-'EOS', @shellcraft.open('/etc/passwd', 'O_CREAT', 0o750))
  /* push "/etc/passwd\x00" */
  push 0x1010101
  xor dword ptr [esp], 0x1657672 /* 0x1010101 ^ 0x647773 */
  push 0x7361702f
  push 0x6374652f
  /* call open("esp", "O_CREAT", 488) */
  push 5 /* (SYS_open) */
  pop eax
  mov ebx, esp
  push 0x40 /* (O_CREAT) */
  pop ecx
  xor edx, edx
  mov dx, 0x1e8
  int 0x80
      EOS
    end
  end
end
