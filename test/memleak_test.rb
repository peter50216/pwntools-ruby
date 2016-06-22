# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/memleak'

class MemLeakTest < MiniTest::Test
  def setup
    @binsh = File.binread('/bin/sh')
    @leak = Pwnlib::MemLeak.new { |addr| @binsh[addr] }
  end

  def test_find_elf_base
    assert_equal(0, @leak.find_elf_base(@binsh.length * 2 / 3))
  end

  def test_n
    assert_equal("\x7fELF", @leak.n(0, 4))
    assert_equal(@binsh[0xf0, 0x20], @leak.n(0xf0, 0x20))
    assert_equal(@binsh[514, 0x20], @leak.n(514, 0x20))
  end

  def test_b
    assert_equal(@binsh[0x100], @leak.b(0x100))
    assert_equal(@binsh[514], @leak.b(514))
  end

  def test_w
    assert_equal(Pwnlib::Util::Packing.u16(@binsh[0x100, 2]), @leak.w(0x100))
    assert_equal(Pwnlib::Util::Packing.u16(@binsh[514, 2]), @leak.w(514))
  end

  def test_d
    assert_equal(Pwnlib::Util::Packing.u32(@binsh[0, 4]), @leak.d(0))
    assert_equal(Pwnlib::Util::Packing.u32(@binsh[0x100, 4]), @leak.d(0x100))
    assert_equal(Pwnlib::Util::Packing.u32(@binsh[514, 4]), @leak.d(514))
  end

  def test_q
    assert_equal(Pwnlib::Util::Packing.u64(@binsh[0x100, 8]), @leak.q(0x100))
    assert_equal(Pwnlib::Util::Packing.u64(@binsh[514, 8]), @leak.q(514))
  end
end
