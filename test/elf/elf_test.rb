# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/elf/elf'
require 'pwnlib/logger'

class ELFTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @path_of = ->(file) { File.join(__dir__, '..', 'data', 'elfs', file) }
    @elf = to_elf_silent('i386.prelro.elf')
  end

  def to_elf_silent(filename)
    log_null { ::Pwnlib::ELF::ELF.new(@path_of.call(filename), checksec: false) }
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

    nrelro_elf = to_elf_silent('amd64.nrelro.elf')
    assert_equal(<<-EOS.strip, nrelro_elf.checksec)
RELRO:    No RELRO
Stack:    Canary found
NX:       NX enabled
PIE:      No PIE (0x400000)
    EOS

    frelro_elf = to_elf_silent('amd64.frelro.elf')
    assert_equal(<<-EOS.strip, frelro_elf.checksec)
RELRO:    Full RELRO
Stack:    Canary found
NX:       NX enabled
PIE:      No PIE (0x400000)
    EOS
  end

  def test_inspect
    assert_match(/#<Pwnlib::ELF::ELF:0x[0-9a-f]+>/, @elf.inspect)
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

    elf = to_elf_silent('amd64.frelro.pie.elf')
    assert_nil(elf.plt)
  end

  def test_address
    old_address = @elf.address
    assert_equal(0x8048000, @elf.address)
    old_main = @elf.symbols.main
    new_address = 0x12340000
    @elf.address = new_address
    assert_equal(old_main - old_address + new_address, @elf.symbols.main)

    elf = to_elf_silent('i386.frelro.pie.elf')
    assert_equal(0, elf.address)
    assert_same(0x6c2, elf.symbols.main)
    elf.address = 0xdeadbeef0000
    # use 'equal' instead of 'same' because their +object_id+ are different on Windows.
    assert_equal(0xdeadbeef06c2, elf.symbols.main)
  end

  def test_static
    elf = to_elf_silent('amd64.static.elf')
    assert_equal(<<-EOS.strip, elf.checksec)
RELRO:    Partial RELRO
Stack:    Canary found
NX:       NX enabled
PIE:      No PIE (0x400000)
    EOS
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

  def test_one_gadgets
    libc = ::Pwnlib::ELF::ELF.new(File.join(__dir__, '..', 'data', 'lib64', 'libc.so.6'), checksec: false)
    # Well.. one_gadget(s) may change in the future, so we just check the return type
    val = libc.one_gadgets.first
    assert(val.is_a?(Integer))
    assert_equal(libc.one_gadgets[0], val)
    assert_equal(libc.one_gadgets[-1], libc.one_gadgets.last)

    libc.address = 0xdeadf000
    assert_equal(0xdeadf000 + val, libc.one_gadgets[0])

    assert_output(/execve/) { log_stdout { context.local(log_level: :debug) { libc.one_gadgets[0] } } }
  end
end
