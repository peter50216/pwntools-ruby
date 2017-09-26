# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/syscall'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # See {Generators::X86::Linux#syscall}.
          def syscall(*arguments)
            context.local(arch: 'amd64') do
              cat X86::Linux.syscall(*arguments)
            end
          end
        end
      end
    end
  end
end
