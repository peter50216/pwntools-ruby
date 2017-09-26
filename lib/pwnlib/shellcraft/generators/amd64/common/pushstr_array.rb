require 'pwnlib/shellcraft/generators/amd64/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          module_function

          # See {Pwnlib::Shellcraft::Generators::X86::Common.pushstr_array}.
          def pushstr_array(*args)
            context.local(arch: 'amd64') do
              cat Generators::X86::Common.pushstr_array(*args)
            end
          end
        end
      end
    end
  end
end
