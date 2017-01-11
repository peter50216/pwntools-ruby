# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/reg_sort'

class RegSortTest < MiniTest::Test
  include ::Pwnlib::RegSort::ClassMethod

  def test_check_cycle
    assert_equal([], check_cycle('a', a: 1))
    assert_equal(['a'], check_cycle('a', a: 'a'))
    assert_equal([], check_cycle('a', a: 'b', b: 'c', c: 'b', d: 'a'))
    assert_equal(%w(a b c d), check_cycle('a', a: 'b', b: 'c', c: 'd', d: 'a'))
  end

  def test_regsort
    regs = %w(a b c d x y z)
    # normal
    assert_equal([['mov', 'a', 1], ['mov', 'b', 2]], regsort({ a: 1, b: 2 }, regs))
    # tmp
    assert_equal([%w(mov X a), %w(mov a b), %w(mov b X)], regsort({ a: 'b', b: 'a' }, regs, tmp: 'X'))
    # post move
    assert_equal([['mov', 'a', 1], %w(mov b a)], regsort({ a: 1, b: 1 }, regs))
    assert_equal([%w(mov c a), ['mov', 'a', 1], %w(mov b a)], regsort({ a: 1, b: 1, c: 'a' }, regs))
    # resolve dependencies
    assert_equal([%w(mov b a), ['mov', 'a', 1]], regsort({ a: 1, b: 'a' }, regs))
    assert_equal([['mov', 'c', 3], %w(xchg a b)], regsort({ a: 'b', b: 'a', c: 3 }, regs))
    assert_equal([%w(mov c b), %w(xchg a b)], regsort({ a: 'b', b: 'a', c: 'b' }, regs))
    assert_equal([%w(mov x b), %w(mov y a), %w(mov a b), %w(mov b y)],
                 regsort({ a: 'b', b: 'a', x: 'b' }, regs, tmp: 'y', xchg: false))
    err = assert_raises(ArgumentError) do
      regsort({ a: 1 }, ['b'])
    end
    assert_match(/Unknown register!/, err.message)
    err = assert_raises(ArgumentError) do
      regsort({ a: 'b', b: 'a', x: 'b' }, regs, tmp: 'x', xchg: false)
    end
    assert_match(/Cannot break dependency cycles/, err.message)
    assert_equal([%w(mov x 1), %w(mov y z), %w(mov z c), %w(xchg a b), %w(xchg b c)],
                 regsort({ a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c' }, regs))
    assert_equal([%w(mov x 1), %w(mov y z), %w(mov z c), %w(mov x a), %w(mov a b), %w(mov b c), %w(mov c x)],
                 regsort({ a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c' }, regs, tmp: 'x'))
    assert_equal([%w(mov x 1), %w(mov y z), %w(mov z c), %w(mov x a), %w(mov a b), %w(mov b c), %w(mov c x)],
                 regsort({ a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c' }, regs, xchg: false))
  end
end
