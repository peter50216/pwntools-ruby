# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/sh'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # @overload sh(argv: false)
          #
          # @see Generators::X86::Linux#sh
          def sh(*args)
            context.local(arch: :amd64) do
              cat X86::Linux.sh(*args)
            end
          end
        end
      end
    end
  end
end
