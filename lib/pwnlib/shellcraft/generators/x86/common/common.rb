require 'pwnlib/shellcraft/generators/helper'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        # For non os-related methods.
        module Common
          class << self
            def define_arch_dependent_method(method)
              define_method(method) do |*args|
                if context.arch == 'amd64'
                  cat Generators::Amd64::Common.public_send(method, *args)
                elsif context.arch == 'i386'
                  cat Generators::I386::Common.public_send(method, *args)
                end
              end
            end
          end

          extend Helper
        end
      end
    end
  end
end
