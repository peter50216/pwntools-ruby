# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/x86/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Common
          # Set registers to given values. See example for clearly usage.
          #
          # @param [Hash{Symbol => String, Symbol, Numeric}] reg_context
          #   The values of each registers to be set, see examples.
          # @param [Boolean] stack_allowed
          #   If we can use stack for setting values.
          #   With +stack_allowd+ equals +true+, shellcode would be shorter.
          #
          # @example
          #   puts setregs(rax: 'ebx', ebx: 'ecx', ecx: 0x123)
          #   #  mov rax, rbx
          #   #  mov ebx, ecx
          #   #  xor ecx, ecx
          #   #  mov cx, 0x123
          #
          #   puts setregs(rdi: 'rsi', rsi: 'rdi')
          #   #  xchg rdi, rsi
          #
          #   puts setregs(rax: -1)
          #   #  push -1
          #   #  pop rax
          #
          #   puts setregs({rax: -1}, stack_allowed: false)
          #   #  mov rax, -1
          def setregs(reg_context, stack_allowed: true)
            abi = ::Pwnlib::ABI::ABI.default
            reg_context = reg_context.reject { |_, v| v.nil? }
            # convert all registers to string
            reg_context = reg_context.map do |k, v|
              v = register?(v) ? v.to_s : v
              [k.to_s, v]
            end
            reg_context = reg_context.to_h
            ax_str, dx_str = abi.cdq_pair
            eax = reg_context[ax_str]
            edx = reg_context[dx_str]
            cdq = false
            ev = lambda do |reg|
              return reg unless reg.is_a?(String)
              evaluate(reg)
            end
            eax = ev[eax]
            edx = ev[edx]

            if eax.is_a?(Numeric) && edx.is_a?(Numeric) && edx.zero? && (eax & (1 << 31)).zero?
              # @diff
              #   The condition is wrong in python-pwntools, and here we don't care the case of edx==0xffffffff.
              cdq = true
              reg_context.delete(dx_str)
            end
            sorted_regs = regsort(reg_context, registers)
            if sorted_regs.empty?
              cat '/* setregs noop */'
            else
              sorted_regs.each do |how, src, dst|
                if how == 'xchg'
                  cat "xchg #{src}, #{dst}"
                else
                  # Bug in python-pwntools, which is missing `stack_allowed`.
                  # Proof of bug: pwnlib.shellcraft.setregs({'rax': 1}, stack_allowed=False)
                  cat Common.mov(src, dst, stack_allowed: stack_allowed)
                end
              end
            end
            cat "cdq /* #{dx_str}=0 */" if cdq
          end
        end
      end
    end
  end
end
