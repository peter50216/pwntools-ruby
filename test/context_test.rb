require 'test_helper'
require 'pwnlib/context'

class ContextTest < MiniTest::Test
  def test_set_arch
    context.arch = 'amd64'
    assert_equal(context.arch, 'amd64')
    assert_equal(context.bits, 64)
    assert_equal(context.endian, 'little')
  end

  include Pwnlib::Context
  private :context
end

