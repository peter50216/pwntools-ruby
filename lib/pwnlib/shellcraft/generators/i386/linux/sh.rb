# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/sh'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # @overload sh(argv: false)
          #
          # @see Generators::X86::Linux#sh
          def sh(**kwargs)
            context.local(arch: :i386) do
              cat X86::Linux.sh(**kwargs)
            end
          end
        end
      end
    end
  end
end
