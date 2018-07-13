# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/syscall'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # @overload syscall(*arguments)
          #
          # @see Generators::X86::Linux#syscall
          def syscall(*args)
            context.local(arch: :i386) do
              cat X86::Linux.syscall(*args)
            end
          end
        end
      end
    end
  end
end
