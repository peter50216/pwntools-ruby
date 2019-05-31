# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'open3'

require 'tty-platform'

require 'test_helper'

require 'pwnlib/memleak'

class MemLeakTest < MiniTest::Test
  def setup
    @victim = IO.binread(File.expand_path('data/victim32', __dir__))
    @leak = ::Pwnlib::MemLeak.new { |addr| @victim[addr] }
  end

  def test_n
    assert_equal("\x7fELF", @leak.n(0, 4))
    assert_equal(@victim[0xf0, 0x20], @leak.n(0xf0, 0x20))
    assert_equal(@victim[514, 0x20], @leak.n(514, 0x20))
  end

  def test_b
    assert_equal(::Pwnlib::Util::Packing.u8(@victim[0x100]), @leak.b(0x100))
    assert_equal(::Pwnlib::Util::Packing.u8(@victim[514]), @leak.b(514))
  end

  def test_w
    assert_equal(::Pwnlib::Util::Packing.u16(@victim[0x100, 2]), @leak.w(0x100))
    assert_equal(::Pwnlib::Util::Packing.u16(@victim[514, 2]), @leak.w(514))
  end

  def test_d
    assert_equal(::Pwnlib::Util::Packing.u32(@victim[0, 4]), @leak.d(0))
    assert_equal(::Pwnlib::Util::Packing.u32(@victim[0x100, 4]), @leak.d(0x100))
    assert_equal(::Pwnlib::Util::Packing.u32(@victim[514, 4]), @leak.d(514))
  end

  def test_q
    assert_equal(::Pwnlib::Util::Packing.u64(@victim[0x100, 8]), @leak.q(0x100))
    assert_equal(::Pwnlib::Util::Packing.u64(@victim[514, 8]), @leak.q(514))
  end
end
