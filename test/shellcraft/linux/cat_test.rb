# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class CatTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.cat('flag'))
  /* push "flag\x00" */
  push 0x67616c66
  /* call open("rsp", "O_RDONLY", 0) */
  push 2 /* (SYS_open) */
  pop rax
  mov rdi, rsp
  xor esi, esi /* (O_RDONLY) */
  cdq /* rdx=0 */
  syscall
  /* call sendfile(1, "rax", 0, 2147483647) */
  push 1
  pop rdi
  mov rsi, rax
  push 0x28 /* (SYS_sendfile) */
  pop rax
  mov r10d, 0x7fffffff
  cdq /* rdx=0 */
  syscall
      EOS
      assert_equal(<<-'EOS', @shellcraft.cat('flag', fd: 2))
  /* push "flag\x00" */
  push 0x67616c66
  /* call open("rsp", "O_RDONLY", 0) */
  push 2 /* (SYS_open) */
  pop rax
  mov rdi, rsp
  xor esi, esi /* (O_RDONLY) */
  cdq /* rdx=0 */
  syscall
  /* call sendfile(2, "rax", 0, 2147483647) */
  push 2
  pop rdi
  mov rsi, rax
  push 0x28 /* (SYS_sendfile) */
  pop rax
  mov r10d, 0x7fffffff
  cdq /* rdx=0 */
  syscall
      EOS
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal(<<-'EOS', @shellcraft.cat('flag'))
  /* push "flag\x00" */
  push 1
  dec byte ptr [esp]
  push 0x67616c66
  /* call open("esp", "O_RDONLY", 0) */
  push 5 /* (SYS_open) */
  pop eax
  mov ebx, esp
  xor ecx, ecx /* (O_RDONLY) */
  cdq /* edx=0 */
  int 0x80
  /* call sendfile(1, "eax", 0, 2147483647) */
  push 1
  pop ebx
  mov ecx, eax
  xor eax, eax
  mov al, 0xbb /* (SYS_sendfile) */
  mov esi, 0x7fffffff
  cdq /* edx=0 */
  int 0x80
      EOS
    end
  end
end
