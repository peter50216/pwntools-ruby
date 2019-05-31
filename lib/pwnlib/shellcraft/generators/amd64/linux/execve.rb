# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/execve'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # @overload execve(path, argv, envp)
          #
          # @see Generators::X86::Linux#execve
          def execve(*args)
            context.local(arch: :amd64) do
              cat X86::Linux.execve(*args)
            end
          end
        end
      end
    end
  end
end
