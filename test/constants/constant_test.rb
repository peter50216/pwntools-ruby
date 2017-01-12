# encoding: ASCII-8BIT

require 'test_helper'
require 'pwnlib/constants/constant'

class ConstantTest < MiniTest::Test
  Constant = ::Pwnlib::Constants::Constant

  def test_methods
    a1 = Constant.new('a', 1)
    assert_equal(1, a1.to_i)
    assert_equal(3, a1 | 2)
    assert_operator(a1, :==, 1)
    # test coerce
    assert_operator(1, :==, a1)
    assert_operator(a1, :==, Constant.new('b', 1))
    refute_operator(a1, :==, Constant.new('a', 3))
    assert_equal(3, a1 | Constant.new('a', 2))
    assert_equal(3, 2 | a1)
    assert_equal(1, 2 - a1)

    assert_equal(a1.method(:chr).call, "\x01")
  end
end
