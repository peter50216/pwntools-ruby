# encoding: ASCII-8BIT

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
          def exit(status = 0)
            cat Linux.syscall('SYS_exit', status)
          end
        end
      end
    end
  end
end
