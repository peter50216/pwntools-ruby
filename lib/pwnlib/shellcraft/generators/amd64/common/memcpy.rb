# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/common/common'
require 'pwnlib/shellcraft/generators/amd64/common/setregs'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          def memcpy(dst, src, n)
            cat "/* memcpy(#{pretty(dst)}, #{pretty(src)}, #{pretty(n)}) */"
            cat 'cld'
            cat Common.setregs(rdi: dst, rsi: src, rcx: n)
            cat 'rep movsb'
          end
        end
      end
    end
  end
end
