require 'pwnlib/shellcraft/generators/amd64/common/common'
require 'pwnlib/shellcraft/generators/x86/common/infloop'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # See {X86::Common#infloop}.
          def infloop
            cat Generators::X86::Common.infloop
          end
        end
      end
    end
  end
end
