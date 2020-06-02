# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/amd64/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/cat'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Linux
          # @overload cat(filename, fd: 1)
          #
          # @see Generators::X86::Linux#cat
          def cat(*args, **kwargs)
            context.local(arch: :amd64) do
              cat X86::Linux.cat(*args, **kwargs)
            end
          end
        end
      end
    end
  end
end
