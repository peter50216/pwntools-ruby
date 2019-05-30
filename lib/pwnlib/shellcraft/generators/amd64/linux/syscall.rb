# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/syscall'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # @overload syscall(*arguments)
          #
          # @see Generators::X86::Linux#syscall
          def syscall(*args)
            context.local(arch: :amd64) do
              cat X86::Linux.syscall(*args)
            end
          end
        end
      end
    end
  end
end
