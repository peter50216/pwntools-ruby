# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class ShellcraftTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft.instance
  end

  def test_respond
    assert @shellcraft.respond_to?(:amd64)
    context.local(arch: 'amd64') { assert @shellcraft.respond_to?(:mov) }
    refute @shellcraft.respond_to?(:linux)

    assert_raises(NoMethodError) { @shellcraft.meow }
  end
end
