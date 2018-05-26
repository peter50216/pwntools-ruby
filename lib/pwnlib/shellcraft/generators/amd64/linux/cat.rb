# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/cat'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # @overload cat(filename, fd: 1)
          #
          # @see Generators::X86::Linux#cat
          def cat(*args)
            context.local(arch: :amd64) do
              cat X86::Linux.cat(*args)
            end
          end
        end
      end
    end
  end
end
