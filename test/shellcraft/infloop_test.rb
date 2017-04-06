# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class InfloopTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal("  jmp $\n", @shellcraft.infloop)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal("  jmp $\n", @shellcraft.infloop)
    end
  end
end
