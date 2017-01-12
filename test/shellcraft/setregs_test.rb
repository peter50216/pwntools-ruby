# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class SetregsTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Root.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.setregs(rax: 1, rbx: 'rax'))
  mov rbx, rax
  push 1
  pop rax
      EOS
      assert_equal(<<-'EOS', @shellcraft.setregs(rax: 'SYS_write', rbx: 'rax'))
  mov rbx, rax
  push (SYS_write) /* 1 */
  pop rax
      EOS
      assert_equal(<<-'EOS', @shellcraft.setregs(rax: 'rbx', rbx: 'rax', rcx: 'rbx'))
  mov rcx, rbx
  xchg rax, rbx
      EOS
      assert_equal(<<-'EOS', @shellcraft.setregs(rax: 1, rdx: 0))
  push 1
  pop rax
  cdq /* rdx=0 */
      EOS
    end
  end
end
