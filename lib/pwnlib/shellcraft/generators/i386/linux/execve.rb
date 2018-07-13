# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/execve'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # @overload execve(path, argv, envp)
          #
          # @see Generators::X86::Linux#execve
          def execve(*args)
            context.local(arch: :i386) do
              cat X86::Linux.execve(*args)
            end
          end
        end
      end
    end
  end
end
