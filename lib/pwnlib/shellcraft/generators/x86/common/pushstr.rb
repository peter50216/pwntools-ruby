# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/common/pushstr'
require 'pwnlib/shellcraft/generators/i386/common/pushstr'
require 'pwnlib/shellcraft/generators/x86/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Common
          define_arch_dependent_method :pushstr
        end
      end
    end
  end
end
