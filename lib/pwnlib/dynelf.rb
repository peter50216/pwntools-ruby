# encoding: ASCII-8BIT
require 'pwnlib/context'
require 'pwnlib/util/packing'
require 'pwnlib/memleak'

# TODO(hh): Use MemLeak instead of leak
# TODO(hh): Use ELF datatype instead of magic offset

module Pwnlib
  # DynELF class, resolve symbols in loaded, dynamically-linked ELF binaries.
  # Given a function which can leak data at an arbitrary address,
  # any symbol in any loaded library can be resolved.
  class DynELF
    PT_DYNAMIC = 2
    DT_GNU_HASH = 0x6ffffef5
    DT_HASH = 4
    DT_STRTAB = 5
    DT_SYMTAB = 6

    attr_reader :libbase

    def initialize(addr, &block)
      @leak = Pwnlib::MemLeak.new(&block)
      @libbase = @leak.find_elf_base(addr)
      @elfclass = { "\x01" => 32, "\x02" => 64 }[@leak.b(@libbase + 4)]
      @elfword = @elfclass / 8
      @unp = ->(x) { Util::Packing.send({ 32 => :u32, 64 => :u64 }[@elfclass], x) }
      @dynamic = find_dynamic
      @hshtab = @strtab = @symtab = nil
    end

    def lookup(symb)
      @hshtab ||= find_dt(DT_GNU_HASH)
      @strtab ||= find_dt(DT_STRTAB)
      @symtab ||= find_dt(DT_SYMTAB)
      resolve_symbol_gnu(symb)
    end

    private

    # Function used to generated GNU-style hashes for strings.
    def gnu_hash(s)
      s.bytes.inject(5381) { |a, e| (a * 33 + e) & 0xffffffff }
    end

    def find_dynamic
      e_phoff_offset = { 32 => 28, 64 => 32 }[@elfclass]
      e_phoff = @libbase + @unp.call(@leak.n(@libbase + e_phoff_offset, @elfword))
      phdr_size = { 32 => 32, 64 => 56 }[@elfclass]
      loop do
        ptype = @leak.d(e_phoff)
        break if ptype == PT_DYNAMIC
        e_phoff += phdr_size
      end
      offset = { 32 => 8, 64 => 16 }[@elfclass]
      @unp.call(@leak.n(e_phoff + offset, @elfword))
    end

    def find_dt(tag)
      dyn_size = @elfword * 2
      ptr = @dynamic
      loop do
        tmp = @leak.n(ptr, @elfword * 2)
        d_tag = @unp.call(tmp[0, @elfword])
        d_addr = @unp.call(tmp[@elfword, @elfword])
        break if d_tag == 0
        return d_addr if tag == d_tag
        ptr += dyn_size
      end
      nil
    end

    def resolve_symbol_gnu(symb)
      sym_size = { 32 => 16, 64 => 24 }[@elfclass]
      # Leak GNU_HASH section header
      nbuckets = @leak.d(@hshtab)
      symndx = @leak.d(@hshtab + 4)
      maskwords = @leak.d(@hshtab + 8)

      l_gnu_buckets = @hshtab + 16 + (@elfword * maskwords)
      l_gnu_chain_zero = l_gnu_buckets + (4 * nbuckets) - (4 * symndx)

      hsh = gnu_hash(symb)
      bucket = hsh % nbuckets

      i = @leak.d(l_gnu_buckets + bucket * 4)
      return nil if i == 0

      hsh2 = 0
      while (hsh2 & 1) == 0
        hsh2 = @leak.d(l_gnu_chain_zero + i * 4)
        if ((hsh ^ hsh2) >> 1) == 0
          sym = @symtab + sym_size * i
          st_name = @leak.d(sym)
          name = @leak.n(@strtab + st_name, symb.length + 1)
          if name == (symb + "\x00")
            offset = { 32 => 4, 64 => 8 }[@elfclass]
            st_value = @unp.call(@leak.n(sym + offset, @elfword))
            return @libbase + st_value
          end
        end
        i += 1
      end
      nil
    end
  end
end
