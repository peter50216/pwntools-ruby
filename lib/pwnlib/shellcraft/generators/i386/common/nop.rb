require 'pwnlib/shellcraft/generators/i386/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Common
          module_function

          # A No-op instruction.
          def nop
            cat 'nop'
          end
        end
      end
    end
  end
end
