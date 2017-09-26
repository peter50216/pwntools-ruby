require 'pwnlib/abi'
require 'pwnlib/constants/constant'
require 'pwnlib/shellcraft/generators/amd64/common/setregs'
require 'pwnlib/shellcraft/generators/helper'
require 'pwnlib/shellcraft/generators/i386/common/setregs'
require 'pwnlib/shellcraft/registers'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        # For os-related methods.
        module Linux
          %i[setregs].each do |m|
            define_method(m) do |*args|
              if context.arch == 'amd64'
                Generators::Amd64::Common.public_send(m, *args)
              elsif context.arch == 'i386'
                Generators::I386::Common.public_send(m, *args)
              end
            end
          end

          extend ::Pwnlib::Shellcraft::Registers
          # There's method hook in Helper module, so extend in the last line.
          extend ::Pwnlib::Shellcraft::Generators::Helper
        end
      end
    end
  end
end
