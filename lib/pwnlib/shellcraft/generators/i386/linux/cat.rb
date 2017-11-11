require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/cat'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # See #{Generators::X86::Linux#cat}.
          def cat(*args)
            context.local(arch: 'i386') do
              cat X86::Linux.cat(*args)
            end
          end
        end
      end
    end
  end
end
