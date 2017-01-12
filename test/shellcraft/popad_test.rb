# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class PopadTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Root.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.popad)
  pop rdi
  pop rsi
  pop rbp
  add rsp, 8
  pop rbx
  pop rdx
  pop rcx
  pop rax
      EOS
    end
  end
end
