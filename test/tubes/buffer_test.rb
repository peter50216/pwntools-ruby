# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/tubes/buffer'

class BufferTest < MiniTest::Test
  def test_add
    b = ::Pwnlib::Tubes::Buffer.new
    b.add('A' * 10)
    b.add('B' * 10)
    assert_equal(20, b.size)
    assert_equal('A', b.get(1))
    assert_equal(19, b.size)
    assert_equal(false, b.empty?)
    assert_equal('AAAAAAAAABBBBBBBBBB', b.get(9999))
    assert_equal(0, b.size)
    assert_equal(true, b.empty?)
    assert_equal('', b.get(1))
  end

  def test_unget
    b = ::Pwnlib::Tubes::Buffer.new
    b.add('hello')
    b.add('world')
    assert_equal('hello', b.get(5))
    b.unget('goodbye')
    assert_equal('goodbyeworld', b.get)
  end

  def test_buffer
    b = ::Pwnlib::Tubes::Buffer.new
    b2 = ::Pwnlib::Tubes::Buffer.new
    b.add('hello')
    b2.add('world')
    b.add(b2)
    assert_equal('hello', b.get(5))
    assert_equal(false, b2.empty?)
    assert_equal('world', b2.get)
    b2.add('goodbye')
    b.unget(b2)
    assert_equal('goodbyeworld', b.get)
    assert_equal('goodbye', b2.get)
  end
end
