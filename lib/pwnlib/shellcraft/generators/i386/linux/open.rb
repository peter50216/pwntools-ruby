# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/open'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # @overload open(filename, flags, mode = 0)
          #
          # @see Generators::X86::Linux#open
          def open(*args)
            context.local(arch: :i386) do
              cat X86::Linux.open(*args)
            end
          end
        end
      end
    end
  end
end
