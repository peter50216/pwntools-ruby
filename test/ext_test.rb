# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/ext/string'
require 'pwnlib/ext/integer'
require 'pwnlib/ext/array'

class ExtTest < MiniTest::Test
  # Thought that test one method in each module for each type is enough, since it's quite
  # stupid (and meaningless) to copy the list of proxied functions to here...
  def test_ext_string
    assert_equal(0x4142, 'AB'.u16(endian: 'be'))
    assert_equal([1, 1, 0, 0, 0, 1, 0, 0], "\xC4".bits)
  end

  def test_ext_integer
    assert_equal('AB', 0x4241.p16)
    assert_equal([0, 0, 1, 1, 0, 1, 0, 0], 0x34.bits)
    assert_equal(2**31, 1.bitswap)
  end

  def test_ext_array
    assert_equal("\xfe", [1, 1, 1, 1, 1, 1, 1, 0].unbits)
    assert_equal("XX\xef\xbe\xad\xdeXX", ['XX', 0xdeadbeef, 'XX'].flat)
  end
end
