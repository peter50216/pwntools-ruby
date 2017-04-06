# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class SyscallTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.syscall('SYS_execve', 1, 'rsp', 2, 0))
  /* call execve(1, "rsp", 2, 0) */
  push 0x3b /* (SYS_execve) */
  pop rax
  push 1
  pop rdi
  mov rsi, rsp
  push 2
  pop rdx
  xor r10d, r10d /* 0 */
  syscall
      EOS
      assert_equal(<<-'EOS', @shellcraft.syscall)
  /* call syscall() */
  syscall
      EOS
      assert_equal(<<-'EOS', @shellcraft.syscall('rax', 'rdi', 'rsi'))
  /* call syscall("rax", "rdi", "rsi") */
  /* setregs noop */
  syscall
      EOS
      assert_equal(<<-'EOS', @shellcraft.syscall('rbp', nil, nil, 1))
  /* call syscall("rbp", ?, ?, 1) */
  mov rax, rbp
  push 1
  pop rdx
  syscall
      EOS
      mmap = @shellcraft.syscall('SYS_mmap', 0, 4096,
                                 'PROT_READ | PROT_WRITE | PROT_EXEC',
                                 'MAP_PRIVATE | MAP_ANONYMOUS', -1, 0)
      assert_equal(<<-'EOS', mmap)
  /* call mmap(0, 4096, "PROT_READ | PROT_WRITE | PROT_EXEC", "MAP_PRIVATE | MAP_ANONYMOUS", -1, 0) */
  push 9 /* (SYS_mmap) */
  pop rax
  xor edi, edi /* 0 */
  mov esi, 0x1010101 /* 4096 == 0x1000 */
  xor esi, 0x1011101
  push 7 /* (PROT_READ | PROT_WRITE | PROT_EXEC) */
  pop rdx
  push 0x22 /* (MAP_PRIVATE | MAP_ANONYMOUS) */
  pop r10
  push -1
  pop r8
  xor r9d, r9d /* 0 */
  syscall
      EOS
    end
  end
end
