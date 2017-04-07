# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class SetregsTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft.instance
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
  push 1 /* (SYS_write) */
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

  def test_i386
    context.local(arch: 'i386') do
      assert_equal(<<-EOS, @shellcraft.setregs(eax: 1, ebx: 'eax'))
  mov ebx, eax
  push 1
  pop eax
      EOS
      assert_equal(<<-EOS, @shellcraft.setregs(eax: 'ebx', ebx: 'eax', ecx: 'ebx'))
  mov ecx, ebx
  xchg eax, ebx
      EOS
      assert_equal(<<-'EOS', @shellcraft.setregs(eax: 1, edx: 0))
  push 1
  pop eax
  cdq /* edx=0 */
      EOS
    end
  end
end
