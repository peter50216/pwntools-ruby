# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/common/common'
require 'pwnlib/shellcraft/generators/x86/common/infloop'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Common
          # @overload infloop
          #
          # @see Generators::X86::Common#infloop
          def infloop(*args)
            context.local(arch: :i386) do
              cat X86::Common.infloop(*args)
            end
          end
        end
      end
    end
  end
end
