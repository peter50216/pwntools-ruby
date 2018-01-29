# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/x86/linux/linux'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # Push filename onto stack and perform open syscall.
          #
          # @param [String] filename
          #   The file to be opened.
          # @param [String, Integer] flags
          #   Flags for opening a file.
          # @param [Integer] mode
          #   If +filename+ doesn't exist and 'O_CREAT' is specified in +flags+,
          #   +mode+ will be used as the file permission for creating the file.
          #
          # @return [String]
          #   Assembly for open syscall.
          #
          # @example
          #   puts shellcraft.open('/etc/passwd', 'O_RDONLY')
          #   #   /* push "/etc/passwd\x00" */
          #   #   push 0x1010101
          #   #   xor dword ptr [esp], 0x1657672 /* 0x1010101 ^ 0x647773 */
          #   #   push 0x7361702f
          #   #   push 0x6374652f
          #   #   /* call open("esp", "O_RDONLY", 0) */
          #   #   push 5 /* (SYS_open) */
          #   #   pop eax
          #   #   mov ebx, esp
          #   #   xor ecx, ecx /* (O_RDONLY) */
          #   #   cdq /* edx=0 */
          #   #   int 0x80
          def open(filename, flags = 'O_RDONLY', mode = 0)
            abi = ::Pwnlib::ABI::ABI.syscall
            cat Common.pushstr(filename)
            cat Linux.syscall('SYS_open', abi.stack_pointer, flags, mode)
          end
        end
      end
    end
  end
end
