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
      assert_equal(<<-'EOS', @shellcraft.memcpy('rdi', 'rbx', 255))
  /* memcpy("rdi", "rbx", 0xff) */
  cld
  mov rsi, rbx
  xor ecx, ecx
  mov cl, 0xff
  rep movsb
      EOS
    end
  end
end
