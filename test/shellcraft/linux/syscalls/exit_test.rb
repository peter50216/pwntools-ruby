# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class ExitTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.exit)
  /* call exit(0) */
  push 0x3c /* (SYS_exit) */
  pop rax
  xor edi, edi /* 0 */
  syscall
      EOS

      assert_equal(<<-'EOS', @shellcraft.exit(1))
  /* call exit(1) */
  push 0x3c /* (SYS_exit) */
  pop rax
  push 1
  pop rdi
  syscall
      EOS
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal(<<-'EOS', @shellcraft.exit)
  /* call exit(0) */
  push 1 /* (SYS_exit) */
  pop eax
  xor ebx, ebx /* 0 */
  int 0x80
      EOS

      assert_equal(<<-'EOS', @shellcraft.exit(1))
  /* call exit(1) */
  push 1 /* (SYS_exit) */
  pop eax
  push 1
  pop ebx
  int 0x80
      EOS
    end
  end
end
