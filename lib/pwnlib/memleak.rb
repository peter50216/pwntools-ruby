# encoding: ASCII-8BIT
require 'pwnlib/util/packing'

module Pwnlib
  # MemLeak is a caching and heuristic tool for exploiting memory leaks.
  class MemLeak
    PAGE_SIZE = 0x1000
    PAGE_MASK = ~(PAGE_SIZE - 1)

    def initialize(&block)
      @leak = block
      @base = nil
      @cache = {}
    end

    def find_elf_base(ptr)
      ptr &= PAGE_MASK
      loop do
        return @base = ptr if n(ptr, 4) == "\x7fELF"
        ptr -= PAGE_SIZE
      end
    end

    # Call the leaker function on address `addr`.
    # Store the result to @cache
    def do_leak(addr)
      unless @cache.key?(addr)
        data = @leak.call(addr)
        data.bytes.each.with_index(addr) { |b, i| @cache[i] = b }
      end
      @cache[addr]
    end

    # Leak `numb` bytes at `addr`.
    # Returns a string with the leaked bytes.
    def n(addr, numb)
      (0...numb).map { |i| do_leak(addr + i) }.pack('C*')
    end

    # Leak byte at ``((uint8_t*) addr)[ndx]``
    def b(addr)
      n(addr, 1)
    end

    # Leak word at ``((uint16_t*) addr)[ndx]``
    def w(addr)
      Util::Packing.u16(n(addr, 2))
    end

    # Leak dword at ``((uint32_t*) addr)[ndx]``
    def d(addr)
      Util::Packing.u32(n(addr, 4))
    end

    # Leak qword at ``((uint64_t*) addr)[ndx]``
    def q(addr)
      Util::Packing.u64(n(addr, 8))
    end
  end
end
