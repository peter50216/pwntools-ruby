# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class SyscallTest < MiniTest::Test
  include ::Pwnlib::Context
  Shellcraft = ::Pwnlib::Shellcraft

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  /* call execve(1, \"rsp\", 2, 0) */\n  xor r10d, r10d /* 0 */\n  push (SYS_execve) /* 0x3b */\n  pop rax\n  push 1\n  pop rdi\n  push 2\n  pop rdx\n  mov rsi, rsp\n  syscall\n", Shellcraft.syscall('SYS_execve', 1, 'rsp', 2, 0))
      assert_equal("  /* call syscall() */\n  syscall\n", Shellcraft.syscall)
      assert_equal("  /* call syscall(\"rax\", \"rdi\", \"rsi\") */\n  /* setregs noop */\n  syscall\n", Shellcraft.syscall('rax', 'rdi', 'rsi'))
      assert_equal("  /* call syscall(\"rbp\", ?, ?, 1) */\n  mov rax, rbp\n  push 1\n  pop rdx\n  syscall\n", Shellcraft.syscall('rbp', nil, nil, 1))
      # TODO(david942j): Constants.eval
      # mmap(0, 4096, 'PROT_READ | PROT_WRITE | PROT_EXEC', 'MAP_PRIVATE | MAP_ANONYMOUS', -1, 0)
    end
  end
end
