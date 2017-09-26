require 'pwnlib/shellcraft/generators/amd64/common/mov'
require 'pwnlib/shellcraft/generators/amd64/common/pushstr'
require 'pwnlib/shellcraft/generators/helper'
require 'pwnlib/shellcraft/generators/i386/common/mov'
require 'pwnlib/shellcraft/generators/i386/common/pushstr'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        # For non os-related methods.
        module Common
          module_function

          %i[mov pushstr].each do |m|
            define_method(m) do |*args|
              if context.arch == 'amd64'
                Generators::Amd64::Common.public_send(m, *args)
              elsif context.arch == 'i386'
                Generators::I386::Common.public_send(m, *args)
              end
            end
          end

          extend Helper
        end
      end
    end
  end
end
