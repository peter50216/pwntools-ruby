# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'elftools'

require 'pwnlib/context'
require 'pwnlib/memleak'
require 'pwnlib/util/packing'

module Pwnlib
  # DynELF class, resolve symbols in loaded, dynamically-linked ELF binaries.
  # Given a function which can leak data at an arbitrary address, any symbol in any loaded library can be resolved.
  class DynELF
    attr_reader :libbase # @return [Integer] Base of lib.

    # Instantiate a {Pwnlib::DynELF} object.
    #
    # @param [Integer] addr
    #   An address known to be inside the ELF.
    #
    # @yieldparam [Integer] leak_addr
    #   The start address that the leaker should leak from.
    #
    # @yieldreturn [String]
    #   A leaked non-empty byte string, starting from +leak_addr+.
    def initialize(addr, &block)
      @leak = ::Pwnlib::MemLeak.new(&block)
      @libbase = find_base(addr)
      @elfclass = { 0x1 => 32, 0x2 => 64 }[@leak.b(@libbase + 4)]
      @elfword = @elfclass / 8
      @dynamic = find_dynamic
      @hshtab = @strtab = @symtab = nil
    end

    # Lookup a symbol from the ELF.
    #
    # @param [String] symbol
    #   The symbol name.
    #
    # @return [Integer, nil]
    #   The address of the symbol, or +nil+ if not found.
    def lookup(symbol)
      symbol = symbol.to_s
      sym_size = { 32 => 16, 64 => 24 }[@elfclass]
      # Leak GNU_HASH section header.
      nbuckets = @leak.d(hshtab)
      symndx = @leak.d(hshtab + 4)
      maskwords = @leak.d(hshtab + 8)

      l_gnu_buckets = hshtab + 16 + (@elfword * maskwords)
      l_gnu_chain_zero = l_gnu_buckets + (4 * nbuckets) - (4 * symndx)

      hsh = gnu_hash(symbol)
      bucket = hsh % nbuckets

      i = @leak.d(l_gnu_buckets + bucket * 4)
      return nil if i.zero?

      hsh2 = 0
      while (hsh2 & 1).zero?
        hsh2 = @leak.d(l_gnu_chain_zero + i * 4)
        if ((hsh ^ hsh2) >> 1).zero?
          sym = symtab + sym_size * i
          st_name = @leak.d(sym)
          name = @leak.n(strtab + st_name, symbol.length + 1)
          if name == (symbol + "\x00")
            offset = { 32 => 4, 64 => 8 }[@elfclass]
            st_value = unpack(@leak.n(sym + offset, @elfword))
            return @libbase + st_value
          end
        end
        i += 1
      end
      nil
    end

    # Leak the BuildID of the remote libc.so.
    #
    # @return [String?]
    #   Return BuildID in hex format or +nil+.
    def build_id
      build_id_offsets.each do |offset|
        next unless @leak.n(@libbase + offset + 12, 4) == "GNU\x00"

        return @leak.n(@libbase + offset + 16, 20).unpack('H*').first
      end
      nil
    end

    private

    PAGE_SIZE = 0x1000
    PAGE_MASK = ~(PAGE_SIZE - 1)

    def unpack(x)
      Util::Packing.public_send({ 32 => :u32, 64 => :u64 }[@elfclass], x)
    end

    # Function used to generated GNU-style hashes for strings.
    def gnu_hash(s)
      s.bytes.reduce(5381) { |acc, elem| (acc * 33 + elem) & 0xffffffff }
    end

    # Get the base address of the ELF, based on heuristic of finding ELF header.
    # A known address in ELF should be given.
    def find_base(ptr)
      ptr &= PAGE_MASK
      loop do
        return @base = ptr if @leak.n(ptr, 4) == "\x7fELF"

        ptr -= PAGE_SIZE
      end
    end

    def find_dynamic
      e_phoff_offset = { 32 => 28, 64 => 32 }[@elfclass]
      e_phoff = @libbase + unpack(@leak.n(@libbase + e_phoff_offset, @elfword))
      phdr_size = { 32 => 32, 64 => 56 }[@elfclass]
      loop do
        ptype = @leak.d(e_phoff)
        break if ptype == ELFTools::Constants::PT::PT_DYNAMIC

        e_phoff += phdr_size
      end
      offset = { 32 => 8, 64 => 16 }[@elfclass]
      dyn = unpack(@leak.n(e_phoff + offset, @elfword))
      # Sometimes this is an offset instead of an address.
      dyn += @libbase if (0...0x400000).cover?(dyn)
      dyn
    end

    def find_dt(tag)
      dyn_size = @elfword * 2
      ptr = @dynamic
      loop do
        tmp = @leak.n(ptr, @elfword * 2)
        d_tag = unpack(tmp[0, @elfword])
        d_addr = unpack(tmp[@elfword, @elfword])
        break if d_tag.zero?
        return d_addr if tag == d_tag

        ptr += dyn_size
      end
      nil
    end

    def hshtab
      @hshtab ||= find_dt(ELFTools::Constants::DT::DT_GNU_HASH)
    end

    def strtab
      @strtab ||= find_dt(ELFTools::Constants::DT::DT_STRTAB)
    end

    def symtab
      @symtab ||= find_dt(ELFTools::Constants::DT::DT_SYMTAB)
    end

    # Given the corpus of almost all libc to have been released on RedHat, Fedora, Ubuntu, Debian,
    # etc. over the past several years, there is a strong possibility the GNU Build ID section will
    # be at one of the specified addresses.
    def build_id_offsets
      {
        i386: [0x174],
        arm: [0x174],
        thumb: [0x174],
        aarch64: [0x238],
        amd64: [0x270, 0x174],
        powerpc: [0x174],
        powerpc64: [0x238],
        sparc: [0x174],
        sparc64: [0x270]
      }[context.arch.to_sym] || []
    end

    include Context
  end
end
