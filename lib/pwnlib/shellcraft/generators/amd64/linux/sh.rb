require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/sh'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          module_function

          # See #{Generators::X86::Linux.sh}.
          def sh(*args)
            context.local(arch: 'amd64') do
              cat Generators::X86::Linux.sh(*args)
            end
          end
        end
      end
    end
  end
end
