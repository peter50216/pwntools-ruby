# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/util/cyclic'

class CyclicTest < MiniTest::Test
  include Pwnlib::Util::Cyclic

  def test_cyclic
    assert_equal('AAABAACABBABCACBACCBBBCBCCC', cyclic(alphabet: 'ABC', n: 3))
    assert_equal('aaaabaaacaaadaaaeaaa', cyclic(20))
    assert_equal(27_000, cyclic(alphabet: (0...30).to_a, n: 3).size)
    assert_equal([1, 1, 1, 1, 2, 1, 1, 2, 2, 1, 2, 1, 2, 2, 2, 2],
                 cyclic(alphabet: [1, 2], n: 4))
  end
end
