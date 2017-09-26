require 'pwnlib/shellcraft/generators/amd64/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # A no-op instruction.
          def nop
            cat 'nop'
          end
        end
      end
    end
  end
end
