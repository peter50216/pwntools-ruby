# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/x86/common/setregs'
require 'pwnlib/shellcraft/generators/x86/linux/linux'
require 'pwnlib/util/ruby'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # Assembly of +syscall+.
          #
          # @example
          #   context.arch = 'i386'
          #   puts shellcraft.syscall('SYS_open', 'esp', 0, 0)
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
            registers = abi.register_arguments
            reg_ctx = registers.zip(arguments).to_h
            syscall = arguments.first
            if syscall.to_s.start_with?('SYS_')
              fmt = syscall.to_s[4..-1] + '(%s)'
              args = []
            else
              fmt = 'syscall(%s)'
              args = [syscall ? syscall.inspect : '?']
            end
            # arg0 to arg5
            1.upto(6) do |i|
              args.push(arguments[i] ? arguments[i].inspect : '?')
            end
            args.pop while args.last == '?'

            cat "/* call #{format(fmt, args.join(', '))} */"
            cat Common.setregs(reg_ctx) if arguments.any? { |v| !v.nil? }
            cat abi.syscall_str
          end
        end
      end
    end
  end
end
