# encoding: ASCII-8BIT
require 'pwnlib/context'
require 'pwnlib/util/packing'

module Pwnlib
  module DynELF
    class DynELFType
      PAGE_SIZE = 0x1000
      PAGE_MASK = ~(PAGE_SIZE - 1)
      attr_reader :libbase
      def initialize(leak, pointer)
        @leak = leak
        @pointer = pointer
        @libbase = find_base(pointer)
      end

      private
      def find_base(ptr)
        ptr &= PAGE_MASK
        while true
          ret = @leak.call(ptr)
          break if ret.length >= 4 and ret[0,4] == "\x7fELF"
          ptr -= PAGE_SIZE
        end
        return ptr
      end
    end

    def DynELF(leak, pointer)
      DynELFType.new(leak,pointer)
    end
  end
end
