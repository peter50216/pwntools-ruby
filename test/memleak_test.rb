# encoding: ASCII-8BIT

require 'open3'

require 'tty-platform'

require 'test_helper'

require 'pwnlib/memleak'

class MemLeakTest < MiniTest::Test
  def setup
    @victim = IO.binread(File.expand_path('../data/victim32', __FILE__))
    @leak = ::Pwnlib::MemLeak.new { |addr| @victim[addr] }
  end

  def test_find_elf_base_basic
    assert_equal(0, @leak.find_elf_base(@victim.length * 2 / 3))
  end

  def test_find_elf_base_running
    skip 'Only tested on linux' unless TTY::Platform.new.linux?
    [32, 64].each do |b|
      # TODO(hh): Use process instead of popen2
      Open3.popen2(File.expand_path("../data/victim#{b}", __FILE__)) do |i, o, t|
        main_ra = o.readline[2...-1].to_i(16)
        realbase = nil
        IO.readlines("/proc/#{t.pid}/maps").map(&:split).each do |s|
          st, ed = s[0].split('-').map { |x| x.to_i(16) }
          next unless main_ra.between?(st, ed)
          realbase = st
          break
        end
        refute_nil(realbase)
        mem = open("/proc/#{t.pid}/mem", 'rb')
        l2 = ::Pwnlib::MemLeak.new do |addr|
          mem.seek(addr)
          mem.getc
        end
        assert_equal(realbase, l2.find_elf_base(main_ra))
        mem.close
        i.write('bye')
      end
    end
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
