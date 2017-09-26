# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/x86/common/common'
require 'pwnlib/shellcraft/generators/x86/common/mov'
require 'pwnlib/shellcraft/generators/x86/common/pushstr'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Common
          # Push an array of pointers onto the stack.
          #
          # @param [String] reg
          #   Destination register to hold the result pointer.
          # @param [Array<String>] array
          #   List of arguments to push.
          #   NULL termination is normalized so that each argument ends with exactly one NULL byte.
          #
          # @example
          #   puts pushstr_array('eax', ['push', 'een'])
          #   # /* push argument array ["push\x00", "een\x00"] */
          #   # /* push "push\x00een\x00" */
          #   # push 1
          #   # dec byte ptr [esp]
          #   # push 0x1010101
          #   # xor dword ptr [esp], 0x1010101 ^ 0x6e656500
          #   # push 0x68737570
          #   # xor eax, eax /* 0 */
          #   # push eax /* null terminate */
          #   # push 9
          #   # pop eax
          #   # add eax, esp
          #   # push eax /* "een\x00" */
          #   # push 8
          #   # pop eax
          #   # add eax, esp
          #   # push eax /* "push\x00" */
          #   # mov eax, esp
          #   #=> nil
          def pushstr_array(reg, array)
            abi = ::Pwnlib::ABI::ABI.default
            array = array.map { |a| a.gsub(/\x00+\Z/, '') + "\x00" }
            array_str = array.join
            word_size = abi.arg_alignment
            offset = array_str.size + word_size
            cat "/* push argument array #{array.inspect} */"
            cat Common.pushstr(array_str)
            cat Common.mov(reg, 0)
            cat "push #{reg} /* null terminate */"
            array.reverse.each_with_index do |arg, i|
              cat Common.mov(reg, offset + word_size * i - arg.size)
              cat "add #{reg}, #{abi.stack_pointer}"
              cat "push #{reg} /* #{arg.inspect} */"
              offset -= arg.size
            end
            cat Common.mov(reg, abi.stack_pointer)
          end
        end
      end
    end
  end
end
