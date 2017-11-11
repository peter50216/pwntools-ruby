require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/cat'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # See #{Generators::X86::Linux#cat}.
          def cat(*args)
            context.local(arch: 'amd64') do
              cat X86::Linux.cat(*args)
            end
          end
        end
      end
    end
  end
end
