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
      assert_match(/\Ainfloop_\d+:\n  jmp infloop_\d+\n\Z/, @shellcraft.infloop)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_match(/\Ainfloop_\d+:\n  jmp infloop_\d+\n\Z/, @shellcraft.infloop)
    end
  end
end
