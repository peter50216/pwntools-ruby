# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/amd64/common/common'
require 'pwnlib/shellcraft/generators/amd64/common/setregs'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # Like +memcpy+ in glibc.
          #
          # Copy +n+ bytes from +src+ to +dst+.
          #
          # @param [String, Symbol, Integer] dst
          #   Destination.
          # @param [String, Symbol, Integer] src
          #   Source to be copied.
          # @param [Integer] n
          #   The number of bytes to be copied.
          #
          # @example
          #   shellcraft.memcpy('rax', 'rbx', 0x1000)
          def memcpy(dst, src, n)
            cat "/* memcpy(#{pretty(dst)}, #{pretty(src)}, #{pretty(n)}) */"
            cat 'cld'
            cat Common.setregs({ rdi: dst, rsi: src, rcx: n })
            cat 'rep movsb'
          end
        end
      end
    end
  end
end
