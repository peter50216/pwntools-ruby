# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class MemcpyTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.memcpy('rdi', 'rbx', 255))
  /* memcpy("rdi", "rbx", 0xff) */
  cld
  mov rsi, rbx
  xor ecx, ecx
  mov cl, 0xff
  rep movsb
      EOS
      assert_equal(<<-'EOS', @shellcraft.memcpy('rdi', 0x602020, 10))
  /* memcpy("rdi", 0x602020, 0xa) */
  cld
  mov esi, 0x1010101
  xor esi, 0x1612121 /* 0x602020 == 0x1010101 ^ 0x1612121 */
  push 9 /* mov ecx, '\n' */
  pop rcx
  inc ecx
  rep movsb
      EOS
    end
  end

  def test_i386
    context.local(arch: :i386) do
      assert_equal(<<-'EOS', @shellcraft.memcpy('eax', 'ebx', 'ecx'))
  /* memcpy("eax", "ebx", "ecx") */
  cld
  mov edi, eax
  mov esi, ebx
  rep movsb
      EOS
    end
  end
end
