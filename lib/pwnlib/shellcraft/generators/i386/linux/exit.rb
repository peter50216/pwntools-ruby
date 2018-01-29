# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/exit'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # @overload exit(status = 0)
          #
          # @see Generators::X86::Linux#exit
          def exit(*args)
            context.local(arch: :i386) do
              cat X86::Linux.exit(*args)
            end
          end
        end
      end
    end
  end
end
