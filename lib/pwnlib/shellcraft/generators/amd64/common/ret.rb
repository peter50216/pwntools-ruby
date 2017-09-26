# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/common/common'
require 'pwnlib/shellcraft/generators/amd64/common/mov'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          module_function

          def ret(return_value = nil)
            mov('rax', return_value) if return_value
            cat 'ret'
          end
        end
      end
    end
  end
end
