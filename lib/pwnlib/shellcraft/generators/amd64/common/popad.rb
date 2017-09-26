# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # Pop all of the registers onto the stack which i386 popad does.
          def popad
            cat <<-EOS
pop rdi
pop rsi
pop rbp
pop rbx /* add rsp, 8 */
pop rbx
pop rdx
pop rcx
pop rax
            EOS
          end
        end
      end
    end
  end
end
