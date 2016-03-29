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
    assert_equal('%74%65%73%74', urlencode('test'))
  end

  def test_urldecode
    assert_equal('test A', urldecode('test%20%41'))
    assert_equal('%qq', urldecode('%qq', true))
    err = assert_raises(ArgumentError) { urldecode('%qq') }
    assert_match(/Invalid input to urldecode/, err.message)
  end
end
