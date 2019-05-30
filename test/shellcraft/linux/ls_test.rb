# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class LsTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.ls)
  /* push ".\x00" */
  push 0x2e
  /* call open("rsp", 0, 0) */
  push 2 /* (SYS_open) */
  pop rax
  mov rdi, rsp
  xor esi, esi /* 0 */
  cdq /* rdx=0 */
  syscall
  /* call getdents("rax", "rsp", 4096) */
  mov rdi, rax
  push 0x4e /* (SYS_getdents) */
  pop rax
  mov rsi, rsp
  xor edx, edx
  mov dh, 0x1000 >> 8
  syscall
  /* call write(1, "rsp", "rax") */
  push 1
  pop rdi
  mov rsi, rsp
  mov rdx, rax
  push 1 /* (SYS_write) */
  pop rax
  syscall
      EOS
      assert_equal(<<-'EOS', @shellcraft.ls('/usr/bin'))
  /* push "/usr/bin\x00" */
  push 1
  dec byte ptr [rsp]
  mov rax, 0x6e69622f7273752f
  push rax
  /* call open("rsp", 0, 0) */
  push 2 /* (SYS_open) */
  pop rax
  mov rdi, rsp
  xor esi, esi /* 0 */
  cdq /* rdx=0 */
  syscall
  /* call getdents("rax", "rsp", 4096) */
  mov rdi, rax
  push 0x4e /* (SYS_getdents) */
  pop rax
  mov rsi, rsp
  xor edx, edx
  mov dh, 0x1000 >> 8
  syscall
  /* call write(1, "rsp", "rax") */
  push 1
  pop rdi
  mov rsi, rsp
  mov rdx, rax
  push 1 /* (SYS_write) */
  pop rax
  syscall
      EOS
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal(<<-'EOS', @shellcraft.ls)
  /* push ".\x00" */
  push 0x2e
  /* call open("esp", 0, 0) */
  push 5 /* (SYS_open) */
  pop eax
  mov ebx, esp
  xor ecx, ecx /* 0 */
  cdq /* edx=0 */
  int 0x80
  /* call getdents("eax", "esp", 4096) */
  mov ebx, eax
  xor eax, eax
  mov al, 0x8d /* (SYS_getdents) */
  mov ecx, esp
  xor edx, edx
  mov dh, 0x1000 >> 8
  int 0x80
  /* call write(1, "esp", "eax") */
  push 1
  pop ebx
  mov ecx, esp
  mov edx, eax
  push 4 /* (SYS_write) */
  pop eax
  int 0x80
      EOS
    end
  end
end
