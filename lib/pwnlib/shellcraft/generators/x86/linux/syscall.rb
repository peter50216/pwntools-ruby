# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/x86/common/setregs'
require 'pwnlib/shellcraft/generators/x86/linux/linux'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # Assembly of +syscall+.
          #
          # @example
          #   context.arch = 'i386'
          #   puts syscall('SYS_open', 'esp', 0, 0)
          #   # /* call open("esp", 0, 0) */
          #   # push 5 /* (SYS_open) */
          #   # pop eax
          #   # mov ebx, esp
          #   # xor ecx, ecx /* 0 */
          #   # cdq /* edx=0 */
          #   # int 0x80
          #   #=> nil
          def syscall(*arguments)
            abi = ::Pwnlib::ABI::ABI.syscall
            syscall, arg0, arg1, arg2, arg3, arg4, arg5 = arguments
            if syscall.respond_to?(:to_s) && syscall.to_s.start_with?('SYS_')
              syscall_repr = syscall.to_s[4..-1] + '(%s)'
              args = []
            else
              syscall_repr = 'syscall(%s)'
              args = [syscall ? syscall.inspect : '?']
            end
            # arg0 to arg5
            1.upto(6) do |i|
              args.push(arguments[i] ? arguments[i].inspect : '?')
            end

            args.pop while args.last == '?'
            syscall_repr = format(syscall_repr, args.join(', '))
            registers = abi.register_arguments
            arguments = [syscall, arg0, arg1, arg2, arg3, arg4, arg5]
            reg_ctx = registers.zip(arguments).to_h
            cat "/* call #{syscall_repr} */"
            cat Common.setregs(reg_ctx) if arguments.any? { |v| !v.nil? }
            cat abi.syscall_str
          end
        end
      end
    end
  end
end
