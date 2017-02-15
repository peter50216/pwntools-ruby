# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class PushstrTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.pushstr('A'))
  /* push "A\x00" */
  push 0x41
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr("\n"))
  /* push "\n\x00" */
  push 0xb
  dec byte ptr [rsp]
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr('A' * 4))
  /* push "AAAA\x00" */
  push 0x41414141
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr('A' * 8))
  /* push "AAAAAAAA\x00" */
  push 1
  dec byte ptr [rsp]
  mov rax, 0x4141414141414141
  push rax
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr('A' * 8, append_null: false))
  /* push "AAAAAAAA" */
  mov rax, 0x4141414141414141
  push rax
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr("\n" * 4))
  /* push "\n\n\n\n\x00" */
  push 0x1010101 ^ 0xa0a0a0a
  xor dword ptr [rsp], 0x1010101
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr('/bin/sh'))
  /* push "/bin/sh\x00" */
  mov rax, 0x101010101010101
  push rax
  mov rax, 0x101010101010101 ^ 0x68732f6e69622f
  xor [rsp], rax
      EOS
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal(<<-'EOS', @shellcraft.pushstr('A'))
  /* push "A\x00" */
  push 0x41
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr("\n"))
  /* push "\n\x00" */
  push 0xb
  dec byte ptr [esp]
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr('A' * 4))
  /* push "AAAA\x00" */
  push 1
  dec byte ptr [esp]
  push 0x41414141
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr('A' * 8))
  /* push "AAAAAAAA\x00" */
  push 1
  dec byte ptr [esp]
  push 0x41414141
  push 0x41414141
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr('A' * 8, append_null: false))
  /* push "AAAAAAAA" */
  push 0x41414141
  push 0x41414141
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr("\n" * 4))
  /* push "\n\n\n\n\x00" */
  push 1
  dec byte ptr [esp]
  push 0x1010101
  xor dword ptr [esp], 0x1010101 ^ 0xa0a0a0a
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr('/bin/sh'))
  /* push "/bin/sh\x00" */
  push 0x1010101
  xor dword ptr [esp], 0x1010101 ^ 0x68732f
  push 0x6e69622f
      EOS
    end
  end
end
