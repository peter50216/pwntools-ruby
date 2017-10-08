# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/common/common'
require 'pwnlib/shellcraft/generators/amd64/common/mov'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # Instruction return.
          #
          # @param [String, Symbol, Integer] return_value
          #   Set the return value.
          #   Can be name of a register or an immediate value.
          #   +nil+ for not set return value.
          def ret(return_value = nil)
            cat Common.mov('rax', return_value) if return_value
            cat 'ret'
          end
        end
      end
    end
  end
end
