# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/x86/linux/linux'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # Exit syscall.
          #
          # @param [Integer] status
          #   Status code.
          #
          # @return [String]
          #   Assembly for invoking exit syscall.
          #
          # @example
          #   puts shellcraft.exit(1)
          #   #   /* call exit(1) */
          #   #   push 1 /* (SYS_exit) */
          #   #   pop eax
          #   #   push 1
          #   #   pop ebx
          #   #   int 0x80
          def exit(status = 0)
            cat Linux.syscall('SYS_exit', status)
          end
        end
      end
    end
  end
end
