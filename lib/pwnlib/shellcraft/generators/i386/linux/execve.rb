# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/execve'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # See {Generators::X86::Linux.execve}.
          def execve(*arguments)
            context.local(arch: 'i386') do
              cat Generators::X86::Linux.execve(*arguments)
            end
          end
        end
      end
    end
  end
end
