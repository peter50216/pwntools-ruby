# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class ShellcraftTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Root.instance
  end

  def test_respond_to?
    assert @shellcraft.respond_to?(:amd64)
    context.local(arch: 'amd64') { assert @shellcraft.respond_to?(:mov) }
    refute @shellcraft.respond_to?(:linux)
  end
end
