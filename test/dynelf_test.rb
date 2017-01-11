# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/dynelf'
require 'open3'
require 'os'

class DynELFTest < MiniTest::Test
  def test_lookup
    skip 'Only tested on linux' unless OS.linux?
    [32, 64].each do |b|
      # TODO(hh): Use process instead of popen2
      Open3.popen2(File.expand_path("../data/victim#{b}", __FILE__)) do |i, o, t|
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
        # Methods in libc might have multi-versions, so we record and check if
        # we can find one of them.
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
end
