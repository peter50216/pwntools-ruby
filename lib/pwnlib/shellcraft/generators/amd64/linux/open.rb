# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/open'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # @overload open(filename, flags, mode = 0)
          #
          # @see Generators::X86::Linux#open
          def open(*args)
            context.local(arch: :amd64) do
              cat X86::Linux.open(*args)
            end
          end
        end
      end
    end
  end
end
