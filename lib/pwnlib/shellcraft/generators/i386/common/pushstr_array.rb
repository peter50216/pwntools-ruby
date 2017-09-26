module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Common
          module_function
          # See {Pwnlib::Shellcraft::Generators::X86::Common.pushstr_array}.
          def pushstr_array(*args)
            context.local(arch: 'i386') do
              cat Generators::X86::Common.pushstr_array(*args)
            end
          end
        end
      end
    end
  end
end
