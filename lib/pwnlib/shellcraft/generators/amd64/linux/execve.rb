# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/execve'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # See {Generators::X86::Linux#execve}.
          def execve(*arguments)
            context.local(arch: 'amd64') do
              cat Generators::X86::Linux.execve(*arguments)
            end
          end
        end
      end
    end
  end
end
