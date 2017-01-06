# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class PopadTest < MiniTest::Test
  include ::Pwnlib::Context
  Shellcraft = ::Pwnlib::Shellcraft

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  pop rdi\n  pop rsi\n  pop rbp\n  pop rsp\n  pop rbp\n  pop rdx\n  pop rcx\n  pop rax\n", Shellcraft.popad)
    end
  end
end
