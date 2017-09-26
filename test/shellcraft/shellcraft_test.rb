# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class ShellcraftTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_respond
    context.local(arch: 'amd64') do
      # Check respond_to_missing? is well defined
      assert @shellcraft.respond_to?(:mov)
      assert @shellcraft.method(:sh)
    end
    refute @shellcraft.respond_to?(:linux)
    assert_raises(NoMethodError) { @shellcraft.meow }
  end
end
