# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/reg_sort'

class RegSortTest < MiniTest::Test
  include ::Pwnlib::RegSort

  def setup
    @regs = %w(a b c d x y z)
  end

  def test_normal
    assert_equal([['mov', 'a', 1], ['mov', 'b', 2]], regsort({ a: 1, b: 2 }, @regs))
  end

  def test_post_mov
    assert_equal([['mov', 'a', 1], %w(mov b a)], regsort({ a: 1, b: 1 }, @regs))
    assert_equal([%w(mov c a), ['mov', 'a', 1], %w(mov b a)], regsort({ a: 1, b: 1, c: 'a' }, @regs))
  end

  def test_pseudoforest
    # only one connected component
    assert_equal([%w(mov b a), ['mov', 'a', 1]], regsort({ a: 1, b: 'a' }, @regs))
    assert_equal([['mov', 'c', 3], %w(xchg a b)], regsort({ a: 'b', b: 'a', c: 3 }, @regs))
    assert_equal([%w(mov c b), %w(xchg a b)], regsort({ a: 'b', b: 'a', c: 'b' }, @regs))
    assert_equal([%w(mov x 1), %w(mov y z), %w(mov z c), %w(xchg a b), %w(xchg b c)],
                 regsort({ a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c' }, @regs))

    # more than one connected components
    assert_equal([%w(xchg a b), %w(xchg c d)], regsort({ a: 'b', b: 'a', c: 'd', d: 'c' }, @regs))
    assert_equal([%w(mov c b), %w(mov d b), %w(mov z x), %w(xchg a b), %w(xchg x y)],
                 regsort({ a: 'b', b: 'a', c: 'b', d: 'b', x: 'y', y: 'x', z: 'x' }, @regs))
  end

  def test_raise
    err = assert_raises(ArgumentError) do
      regsort({ a: 1 }, ['b'])
    end
    assert_match(/Unknown register!/, err.message)
  end
end
