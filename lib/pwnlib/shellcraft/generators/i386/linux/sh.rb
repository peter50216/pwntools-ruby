require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/sh'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # See #{Generators::X86::Linux#sh}.
          def sh(*args)
            context.local(arch: 'i386') do
              cat Generators::X86::Linux.sh(*args)
            end
          end
        end
      end
    end
  end
end
