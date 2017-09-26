require 'pwnlib/shellcraft/generators/amd64/common/common'
require 'pwnlib/shellcraft/generators/x86/common/setregs'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # See {Generators::X86::Common#setregs}.
          def setregs(*args)
            context.local(arch: 'amd64') do
              cat Generators::X86::Common.setregs(*args)
            end
          end
        end
      end
    end
  end
end
