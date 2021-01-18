# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/helper'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        # For non os-related methods.
        module Common
          class << self
            def define_arch_dependent_method(method)
              define_method(method) do |*args, **kwargs|
                case context.arch
                when 'amd64'
                  cat Amd64::Common.public_send(method, *args, **kwargs)
                when 'i386'
                  cat I386::Common.public_send(method, *args, **kwargs)
                end
              end
            end
          end

          extend ::Pwnlib::Shellcraft::Generators::Helper
        end
      end
    end
  end
end
