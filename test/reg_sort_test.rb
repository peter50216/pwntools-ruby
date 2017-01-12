# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/reg_sort'

class RegSortTest < MiniTest::Test
  include ::Pwnlib::RegSort::ClassMethod

  def setup
    @regs = %w(a b c d x y z)
  end

  def test_normal
    assert_equal([['mov', 'a', 1], ['mov', 'b', 2]], regsort({ a: 1, b: 2 }, @regs))
  end

  def test_tmp
    assert_equal([%w(mov X a), %w(mov a b), %w(mov b X)], regsort({ a: 'b', b: 'a' }, @regs, tmp: 'X'))
  end

  def test_post_mov
    assert_equal([['mov', 'a', 1], %w(mov b a)], regsort({ a: 1, b: 1 }, @regs))
    assert_equal([%w(mov c a), ['mov', 'a', 1], %w(mov b a)], regsort({ a: 1, b: 1, c: 'a' }, @regs))
  end

  def test_pseudoforest
    # only one connected component
    assert_equal([%w(mov b a), ['mov', 'a', 1]], regsort({ a: 1, b: 'a' }, @regs))
    # python-pwntools fails case.
    assert_equal([%w(mov b a), ['mov', 'a', 1]], regsort({ a: 1, b: 'a' }, @regs, xchg: false))
    assert_equal([['mov', 'c', 3], %w(xchg a b)], regsort({ a: 'b', b: 'a', c: 3 }, @regs))
    assert_equal([%w(mov c b), %w(xchg a b)], regsort({ a: 'b', b: 'a', c: 'b' }, @regs))
    assert_equal([%w(mov x 1), %w(mov y z), %w(mov z c), %w(xchg a b), %w(xchg b c)],
                 regsort({ a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c' }, @regs))
    assert_equal([%w(mov x 1), %w(mov y z), %w(mov z c), %w(mov x a), %w(mov a b), %w(mov b c), %w(mov c x)],
                 regsort({ a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c' }, @regs, tmp: 'x'))

    # more than one connected components
    # assert_equal([], regsort({ a: 'b', b: 'a', c: 'd', d: 'c' }, %w(a b c d), tmp: 'c'))
  end

  def test_no_xchg
    assert_equal([%w(mov x b), %w(mov y a), %w(mov a b), %w(mov b y)],
                 regsort({ a: 'b', b: 'a', x: 'b' }, @regs, tmp: 'y', xchg: false))
  end

  def test_raise
    err = assert_raises(ArgumentError) do
      regsort({ a: 1 }, ['b'])
    end
    assert_match(/Unknown register!/, err.message)
    err = assert_raises(ArgumentError) do
      regsort({ a: 'b', b: 'a', x: 'b' }, @regs, tmp: 'x', xchg: false)
    end
    assert_match(/Cannot break dependency cycles/, err.message)
  end
end
