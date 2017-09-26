require 'pwnlib/shellcraft/generators/x86/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Common
          module_function

          # Infinite loop.
          #
          # @example
          #   infloop
          #   #=> "infloop_1:\n  jmp infloop_1"
          def infloop
            label = get_label('infloop')
            cat "#{label}:"
            cat "jmp #{label}"
          end
        end
      end
    end
  end
end
