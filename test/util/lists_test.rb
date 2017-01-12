# encoding: ASCII-8BIT

require 'test_helper'
require 'pwnlib/util/lists'

class FiddlingTest < MiniTest::Test
  include ::Pwnlib::Util::Lists::ClassMethods

  def test_slice
    assert_equal(%w(A B C D), slice(1, 'ABCD'))
    assert_equal(%w(AB CD E), slice(2, 'ABCDE'))
    assert_equal(%w(AB CD), slice(2, 'ABCDE', underfull_action: :drop))
    assert_equal(%w(AB CD EX), slice(2, 'ABCDE', underfull_action: :fill, fill_value: 'X'))
    assert_equal(%w(AB CD EF), slice(2, 'ABCDEF', underfull_action: :fill, fill_value: 'X'))
    err = assert_raises(ArgumentError) { slice(2, 'ABCDE', underfull_action: :pusheen) }
    assert_equal('underfull_action expect to be one of :ignore, :drop, and :fill', err.message)
    err = assert_raises(ArgumentError) { slice(2, 'ABCDE', underfull_action: :fill, fill_value: nil) }
    assert_equal('fill_value must be a character', err.message)
  end
end
