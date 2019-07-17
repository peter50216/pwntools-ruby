# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/i386/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/sleep'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Linux
          # @overload sleep(seconds)
          #
          # @see Generators::X86::Linux#sleep
          def sleep(*args)
            context.local(arch: :i386) do
              cat X86::Linux.sleep(*args)
            end
          end
        end
      end
    end
  end
end
