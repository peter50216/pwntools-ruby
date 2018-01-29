# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/exit'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # @overload exit(status = 0)
          #
          # @see Generators::X86::Linux#exit
          def exit(*args)
            context.local(arch: 'amd64') do
              cat X86::Linux.exit(*args)
            end
          end
        end
      end
    end
  end
end
