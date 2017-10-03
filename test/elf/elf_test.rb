# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/elf/elf'
require 'pwnlib/logger'

class ELFTest < MiniTest::Test
  include ::Pwnlib::Logger

  def setup
    @path_of = ->(file) { File.join(__dir__, '..', 'data', 'elfs', file) }
    @elf = ::Pwnlib::ELF::ELF.new(@path_of.call('i386.prelro.elf'), checksec: false)
  end

  # check stdout when loaded
  def test_load
    file = @path_of.call('amd64.prelro.elf')
    assert_output(<<-EOS) { log_stdout { ::Pwnlib::ELF::ELF.new(file) } }
[INFO] #{File.realpath(file).inspect}
    RELRO:    Partial RELRO
    Stack:    Canary found
    NX:       NX enabled
    PIE:      No PIE (0x400000)
    EOS

    file = @path_of.call('amd64.frelro.elf')
    assert_output(<<-EOS) { log_stdout { ::Pwnlib::ELF::ELF.new(file) } }
[WARN] No REL.PLT section found, PLT not loaded
[INFO] #{File.realpath(file).inspect}
    RELRO:    Full RELRO
    Stack:    Canary found
    NX:       NX enabled
    PIE:      No PIE (0x400000)
    EOS
  end

  def test_checksec
    assert_equal(<<-EOS.strip, @elf.checksec)
RELRO:    Partial RELRO
Stack:    Canary found
NX:       NX enabled
PIE:      No PIE (0x8048000)
    EOS

    nrelro_elf = ::Pwnlib::ELF::ELF.new(@path_of.call('amd64.nrelro.elf'), checksec: false)
    assert_equal(<<-EOS.strip, nrelro_elf.checksec)
RELRO:    No RELRO
Stack:    Canary found
NX:       NX enabled
PIE:      No PIE (0x400000)
    EOS

    frelro_elf = ::Pwnlib::ELF::ELF.new(@path_of.call('amd64.frelro.elf'), checksec: false)
    assert_equal(<<-EOS.strip, frelro_elf.checksec)
RELRO:    Full RELRO
Stack:    Canary found
NX:       NX enabled
PIE:      No PIE (0x400000)
    EOS
  end

  def test_got
    assert_same(8, @elf.got.to_h.size)
    assert_same(0x8049ff8, @elf.got['__gmon_start__'])
    assert_same(0x8049ff8, @elf.got[:__gmon_start__])
    assert_same(0x804a000, @elf.symbols['_GLOBAL_OFFSET_TABLE_'])
    assert_same(0x804856d, @elf.symbols['main'])
    assert_same(@elf.symbols.main, @elf.symbols[:main])
  end

  def test_plt
    assert_same(6, @elf.plt.to_h.size)
    assert_same(0x80483b0, @elf.plt.printf)
    assert_same(0x80483f0, @elf.plt[:scanf])

    elf = ::Pwnlib::ELF::ELF.new(@path_of.call('amd64.frelro.pie.elf'), checksec: false)
    assert_nil(elf.plt)
  end

  def test_address
    old_address = @elf.address
    assert_equal(0x8048000, @elf.address)
    old_main = @elf.symbols.main
    new_address = 0x12340000
    @elf.address = new_address
    assert_equal(old_main - old_address + new_address, @elf.symbols.main)

    elf = ::Pwnlib::ELF::ELF.new(@path_of.call('i386.frelro.pie.elf'), checksec: false)
    assert_equal(0, elf.address)
    assert_same(0x6c2, elf.symbols.main)
    elf.address = 0xdeadbeef0000
    # use 'equal' instead of 'same' because their +object_id+ are different on Windows.
    assert_equal(0xdeadbeef06c2, elf.symbols.main)
  end

  def test_search
    elf = ::Pwnlib::ELF::ELF.new(File.join(__dir__, '..', 'data', 'lib32', 'libc.so.6'), checksec: false)
    assert_equal([0x1, 0x15e613], elf.search('ELF').to_a)
    assert_equal(0x15900b, elf.find('/bin/sh').next)

    result = elf.find(/E.F/)
    assert_equal(0x1, result.next)
    assert_equal(0xc8efa, result.next)
    assert_equal(0xc9118, result.next)
    assert_equal(0x158284, result.next)
    assert_equal(0x158285, result.next)

    elf.address = 0x1234000
    assert_equal([0x1234001, 0x1392613], elf.search('ELF').to_a)
    assert_equal(0x138d00b, elf.find('/bin/sh').next)
  end

  def log_stdout
    old = log.instance_variable_get(:@logdev)
    log.instance_variable_set(:@logdev, $stdout)
    yield
    log.instance_variable_set(:@logdev, old)
  end
end
