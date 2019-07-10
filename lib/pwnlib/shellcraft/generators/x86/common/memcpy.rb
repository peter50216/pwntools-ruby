# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/amd64/common/memcpy'
require 'pwnlib/shellcraft/generators/i386/common/memcpy'
require 'pwnlib/shellcraft/generators/x86/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Common
          define_arch_dependent_method :memcpy
        end
      end
    end
  end
end
