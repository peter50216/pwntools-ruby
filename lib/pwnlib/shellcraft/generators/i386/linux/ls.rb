# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/ls'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # @overload ls(dir = '.')
          #
          # @see Generators::X86::Linux#ls
          def ls(*args)
            context.local(arch: :i386) do
              cat X86::Linux.ls(*args)
            end
          end
        end
      end
    end
  end
end
