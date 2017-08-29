# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/elf/elf'

class ELFTest < MiniTest::Test
  def setup
    @data = File.join(__dir__, '..', 'data')
    @elf = ::Pwnlib::ELF::ELF.new(File.join(@data, 'victim32'), checksec: false)
  end

  def test_load
    victim64 = File.join(@data, 'victim64')
    assert_output(<<-EOS) { ::Pwnlib::ELF::ELF.new(victim64) }
RELRO:    No RELRO
Stack:    No canary found
NX:       NX enabled
PIE:      No PIE (0x400000)
    EOS
  end

  def test_checksec
    assert_equal(<<-EOS.strip, @elf.checksec)
RELRO:    No RELRO
Stack:    No canary found
NX:       NX enabled
PIE:      No PIE (0x8048000)
    EOS
  end

  def test_got
    assert_equal(6, @elf.got.to_h.size)
    assert_equal(0x8049774, @elf.got['__gmon_start__'])
    assert_equal(0x8049774, @elf.got[:__gmon_start__])
    assert_equal(0x8049778, @elf.symbols['_GLOBAL_OFFSET_TABLE_'])
    assert_equal(0x804849b, @elf.symbols['main'])
    assert_equal(@elf.symbols.main, @elf.symbols[:main])
  end

  def test_plt
    assert_equal(4, @elf.plt.to_h.size)
    assert_equal(0x8048350, @elf.plt.printf)
    assert_equal(0x8048370, @elf.plt[:setvbuf])
  end

  def test_address
    old_address = @elf.address
    assert_equal(0x8048000, @elf.address)
    old_main = @elf.symbols.main
    new_address = 0x12340000
    @elf.address = new_address
    assert_equal(old_main - old_address + new_address, @elf.symbols.main)
  end
end
