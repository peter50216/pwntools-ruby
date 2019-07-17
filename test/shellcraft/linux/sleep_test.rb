# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'benchmark'

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/runner'
require 'pwnlib/shellcraft/shellcraft'

class SleepTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: :amd64) do
      assert_equal(<<-'EOS', @shellcraft.sleep(10))
  /* push "\n\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" */
  push 1
  dec byte ptr [rsp]
  push 0xb
  dec byte ptr [rsp]
  /* call nanosleep("rsp", 0) */
  push 0x23 /* (SYS_nanosleep) */
  pop rax
  mov rdi, rsp
  xor esi, esi /* 0 */
  syscall
  add rsp, 16 /* recover rsp */
      EOS
    end
  end

  def test_i386
    context.local(arch: :i386) do
      assert_equal(<<-'EOS', @shellcraft.sleep(1 + 3e-9))
  /* push "\x01\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00" */
  push 1
  dec byte ptr [esp]
  push 3
  push 1
  dec byte ptr [esp]
  push 1
  /* call nanosleep("esp", 0) */
  xor eax, eax
  mov al, 0xa2 /* (SYS_nanosleep) */
  mov ebx, esp
  xor ecx, ecx /* 0 */
  int 0x80
  add esp, 16 /* recover esp */
      EOS
    end
  end

  def test_run
    linux_only

    context.local(arch: :amd64) do
      asm = @shellcraft.sleep(0.3) + @shellcraft.exit(0)
      t = Benchmark.realtime { ::Pwnlib::Runner.run_assembly(asm).recvall }
      assert_operator t, :>=, 0.3
    end
  end
end
