# encoding: ASCII-8BIT

require 'open3'

require 'tty-platform'

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/dynelf'

class DynELFTest < MiniTest::Test
  def setup
    skip 'Only tested on linux' unless TTY::Platform.new.linux?
  end

  def test_lookup
    [32, 64].each do |b|
      # TODO(hh): Use process instead of popen2
      Open3.popen2(File.expand_path("data/victim#{b}", __dir__)) do |i, o, t|
        main_ra = Integer(o.readline)
        libc_path = nil
        IO.readlines("/proc/#{t.pid}/maps").map(&:split).each do |s|
          st, ed = s[0].split('-').map { |x| x.to_i(16) }
          next unless main_ra.between?(st, ed)
          libc_path = s[-1]
          break
        end
        refute_nil(libc_path)

        # TODO(hh): Use ELF instead of objdump
        # Methods in libc might have multi-versions, so we record and check if we can find one of them.
        h = Hash.new { |hsh, key| hsh[key] = [] }
        symbols = `objdump -T #{libc_path}`.lines.map(&:split).select { |a| a[2] == 'DF' }
        symbols.map { |a| h[a[-1]] << a[0].to_i(16) }

        mem = open("/proc/#{t.pid}/mem", 'rb')
        d = ::Pwnlib::DynELF.new(main_ra) do |addr|
          mem.seek(addr)
          mem.getc
        end

        assert_nil(d.lookup('pipi_hao_wei!'))
        h.each do |sym, off|
          assert_includes(off, d.lookup(sym) - d.libbase)
        end

        i.write('bye')
      end
    end
  end

  def test_build_id
    [
      [32, 'ac333186c6b532511a68d16aca4c61422eb772da', 'i386'],
      [64, '088a6e00a1814622219f346b41e775b8dd46c518', 'amd64']
    ].each do |b, answer, arch|
      ::Pwnlib::Context.context.arch = arch

      lib_path = File.expand_path("data/lib#{b}/", __dir__)
      ld_path = File.expand_path('ld.so.2', lib_path)
      victim_path = File.expand_path("data/victim#{b}", __dir__)

      Open3.popen2("#{ld_path} --library-path #{lib_path} #{victim_path}") do |i, o, t|
        main_ra = Integer(o.readline)
        mem = open("/proc/#{t.pid}/mem", 'rb')
        d = ::Pwnlib::DynELF.new(main_ra) do |addr|
          mem.seek(addr)
          mem.getc
        end

        assert_equal(answer, d.build_id)

        i.write('bye')
      end
    end
  end
end
