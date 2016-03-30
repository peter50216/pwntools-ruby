# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/util/fiddling'

class FiddlingTest < MiniTest::Test
  include Pwnlib::Util::Fiddling

  def test_enhex
    assert_equal('4141313233', enhex('AA123'))
    assert_equal('74657374', enhex('test'))
    assert_equal('122355ff4499', enhex("\x12\x23\x55\xff\x44\x99"))
    assert_equal('21402324255e262a28295f2b5f29282a265e2524234040213f7b7d5d5b2f2f5c60607e',
                 enhex('!@#$%^&*()_+_)(*&^%$#@@!?{}][//\``~'))
  end

  def test_unhex
    assert_equal('AA123', unhex('4141313233'))
    assert_equal('test', unhex('74657374'))
    assert_equal("\x12\x23\x55\xff\x44\x99", unhex('122355ff4499'))
    assert_equal('!@#$%^&*()_+_)(*&^%$#@@!?{}][//\``~',
                 unhex('21402324255e262a28295f2b5f29282a265e2524234040213f7b7d5d5b2f2f5c60607e'))
  end

  def test_urlencode
    assert_equal('%74%65%73%74%20%41', urlencode('test A'))
    assert_equal('%00%ff%01%fe', urlencode("\x00\xff\x01\xfe"))
  end

  def test_urldecode
    assert_equal('test A', urldecode('te%73t%20%41'))
    assert_equal("\x00\xff\x01\xfe", urldecode('%00%ff%01%fe'))

    assert_equal('%qq', urldecode('%qq', true))
    err = assert_raises(ArgumentError) { urldecode('%qq') }
    assert_match(/Invalid input to urldecode/, err.message)

    assert_equal('%%1z2%orz%%%%%#$!#)@%', urldecode('%%1z2%orz%%%%%#$!#)@%', true))
    err = assert_raises(ArgumentError) { urldecode('%ff%') }
    assert_match(/Invalid input to urldecode/, err.message)
  end

  def test_bits
    assert_equal(['+', '+', '+', '+', '+', '+', '+', '-', '-', '-', '-', '-', '-', '-', '-', '-'],
                 bits(511, zero: '+', one: '-'))
    assert_equal([0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0], bits('XD'))
    assert_equal([0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0],
                 bits('XD', endian: 'le'))
    assert_equal([0, 0, 0, 0, 0, 0, 0, 0], bits(0))

    err = assert_raises(ArgumentError) { bits(2.0) }
    assert_match(/must be either String or Integer/, err.message)

    err = assert_raises(ArgumentError) { bits(-1) }
    assert_match(/must be non-negative/, err.message)
  end

  def test_bits_str
    assert_equal('0000000111111111', bits_str(511))
    assert_equal('0100011010010110001011101100111011111010110011100010111001001110',
                 bits_str('bits_str', endian: 'little'))
  end
end
