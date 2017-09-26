# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class PopadTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.popad)
  pop rdi
  pop rsi
  pop rbp
  pop rbx /* add rsp, 8 */
  pop rbx
  pop rdx
  pop rcx
  pop rax
      EOS
    end
  end
end
