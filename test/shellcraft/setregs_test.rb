# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class SetregsTest < MiniTest::Test
  include ::Pwnlib::Context
  Shellcraft = ::Pwnlib::Shellcraft

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  mov rbx, rax\n  push 1\n  pop rax\n", Shellcraft.setregs(rax: 1, rbx: 'rax'))
      assert_equal("  mov rbx, rax\n  push (SYS_write) /* 1 */\n  pop rax\n", Shellcraft.setregs(rax: 'SYS_write', rbx: 'rax'))
      assert_equal("  mov rcx, rbx\n  xchg rax, rbx\n", Shellcraft.setregs(rax: 'rbx', rbx: 'rax', rcx: 'rbx'))
      assert_equal("  push 1\n  pop rax\n  cdq /* rdx=0 */\n", Shellcraft.setregs(rax: 1, rdx: 0))
    end
  end
end
