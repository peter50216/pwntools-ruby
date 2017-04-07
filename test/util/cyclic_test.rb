# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/util/cyclic'

class CyclicTest < MiniTest::Test
  include ::Pwnlib::Util::Cyclic

  def test_cyclic
    assert_equal('AAABAACABBABCACBACCBBBCBCCC', cyclic(alphabet: 'ABC', n: 3))
    assert_equal('aaaabaaacaaadaaaeaaa', cyclic(20))
    assert_equal(27_000, cyclic(alphabet: (0...30).to_a, n: 3).size)
    assert_equal([1, 1, 1, 1, 2, 1, 1, 2, 2, 1, 2, 1, 2, 2, 2, 2],
                 cyclic(alphabet: [1, 2], n: 4))
  end

  def test_cyclic_find
    r = cyclic(1000)
    10.times do
      idx = rand(0...1000 - 4)
      assert_equal(idx, cyclic_find(r[idx, 4]))
    end

    r = cyclic(1000)
    10.times do
      idx = rand(0...1000 - 5)
      assert_equal(idx, cyclic_find(r[idx, 5], n: 4))
    end

    r = cyclic(1000, alphabet: (0...10).to_a)
    10.times do
      idx = rand(0...1000 - 4)
      assert_equal(idx, cyclic_find(r[idx, 4], alphabet: (0...10).to_a))
    end
  end
end
