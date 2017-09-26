require 'pwnlib/shellcraft/generators/amd64/common/common'
require 'pwnlib/shellcraft/generators/x86/common/pushstr_array'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # See {Pwnlib::Shellcraft::Generators::X86::Common#pushstr_array}.
          def pushstr_array(*args)
            context.local(arch: 'amd64') do
              cat X86::Common.pushstr_array(*args)
            end
          end
        end
      end
    end
  end
end
