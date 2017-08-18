# encoding: ASCII-8BIT

require 'open3'

require 'tty-platform'

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/dynelf'
require 'pwnlib/elf/elf'

class DynELFTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    skip 'Only tested on linux' unless TTY::Platform.new.linux?
  end

  # popen victim with specific libc.so.6
  def popen_victim(b)
    lib_path = File.expand_path("data/lib#{b}/", __dir__)
    libc_path = File.expand_path('libc.so.6', lib_path)
    ld_path = File.expand_path('ld.so.2', lib_path)
    victim_path = File.expand_path("data/victim#{b}", __dir__)

    Open3.popen2("#{ld_path} --library-path #{lib_path} #{victim_path}") do |i, o, t|
      main_ra = Integer(o.readline)
      mem = open("/proc/#{t.pid}/mem", 'rb')
      d = ::Pwnlib::DynELF.new(main_ra) do |addr|
        mem.seek(addr)
        mem.getc
      end

      yield d, { libc: libc_path, main_ra: main_ra, pid: t.pid }

      mem.close
      i.write('bye')
    end
  end

  def test_find_base
    [32, 64].each do |b|
      popen_victim(b) do |d, options|
        main_ra = options[:main_ra]
        realbase = nil
        IO.readlines("/proc/#{options[:pid]}/maps").map(&:split).each do |s|
          st, ed = s[0].split('-').map { |x| x.to_i(16) }
          next unless main_ra.between?(st, ed)
          realbase = st
          break
        end
        refute_nil(realbase)
        assert_equal(realbase, d.libbase)
      end
    end
  end

  def test_lookup
    [32, 64].each do |b|
      popen_victim(b) do |d, options|
        assert_nil(d.lookup('pipi_hao_wei!'))
        elf = ::Pwnlib::ELF::ELF.new(options[:libc], checksec: false)
        %i(system open read write execve printf puts sprintf mmap mprotect).each do |sym|
          assert_equal(d.libbase + elf.symbols[sym], d.lookup(sym))
        end
      end
    end
  end
end
