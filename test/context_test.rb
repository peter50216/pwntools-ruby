require 'test_helper'
require 'pwnlib/context'

class ContextTest < MiniTest::Test
  include Pwnlib::Context

  def test_set_arch
    context.arch = 'amd64'
    assert_equal(context.arch, 'amd64')
    assert_equal(context.bits, 64)
    assert_equal(context.endian, 'little')
  end

  def test_set_bits
    assert_equal(context.bits, 32)
    context.bits = 64
    assert_equal(context.bits, 64)
  end
end
