require 'pwnlib/shellcraft/generators/i386/common/common'
require 'pwnlib/shellcraft/generators/x86/common/infloop'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Common
          def infloop
            cat Generators::X86::Common.infloop
          end
        end
      end
    end
  end
end