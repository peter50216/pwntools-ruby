require 'pwnlib/shellcraft/generators/i386/common/common'
require 'pwnlib/shellcraft/generators/x86/common/setregs'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Common
          # See {Generators::X86::Common.setregs}.
          def setregs(*args)
            context.local(arch: 'i386') do
              cat Generators::X86::Common.setregs(*args)
            end
          end
        end
      end
    end
  end
end
