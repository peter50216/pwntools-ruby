# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/x86/linux/execve'
require 'pwnlib/shellcraft/generators/x86/linux/linux'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # Get shell!
          #
          # @param [Boolean, Array<String>] argv
          #   Arguments of +argv+ when calling +execve+.
          #   If +true+ is given, use +['sh']+.
          #   If +Array<String>+ is given, use it as arguments array.
          #
          # @example
          #   context.arch = 'i386'
          #   puts shellcraft.sh
          #   # /* push "/bin///sh\x00" */
          #   # push 0x68
          #   # push 0x732f2f2f
          #   # push 0x6e69622f
          #   #
          #   # /* call execve("esp", 0, 0) */
          #   # push 0xb /* (SYS_execve) */
          #   # pop eax
          #   # mov ebx, esp
          #   # xor ecx, ecx /* 0 */
          #   # cdq /* edx=0 */
          #   # int 0x80
          #   #=> nil
          #
          # @note Null pointer is always used as +envp+.
          #
          # @diff
          #   By default, this method calls +execve('/bin///sh', 0, 0)+, which is different from pwntools-python:
          #   +execve('/bin///sh', ['sh'], 0)+.
          def sh(argv: false)
            argv = case argv
                   when true then ['sh']
                   when false then 0
                   else argv
                   end
            cat Linux.execve('/bin///sh', argv, 0)
          end
        end
      end
    end
  end
end
