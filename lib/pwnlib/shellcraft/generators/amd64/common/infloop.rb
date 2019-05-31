# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/amd64/common/common'
require 'pwnlib/shellcraft/generators/x86/common/infloop'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # @overload infloop
          #
          # @see Generators::X86::Common#infloop
          def infloop(*args)
            context.local(arch: :amd64) do
              cat X86::Common.infloop(*args)
            end
          end
        end
      end
    end
  end
end
