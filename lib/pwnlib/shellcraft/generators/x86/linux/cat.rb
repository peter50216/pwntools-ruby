# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/x86/common/pushstr'
require 'pwnlib/shellcraft/generators/x86/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/syscall'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # Opens a file and writes its contents to the specified file descriptor.
          #
          # @param [String] filename
          #   The filename.
          # @param [Integer] fd
          #   The file descriptor to write the file contents.
          #
          # @example
          #  context.arch = 'amd64'
          #  puts shellcraft.cat('/etc/passwd')
          #  #  /* push "/etc/passwd\x00" */
          #  #  push 0x1010101 ^ 0x647773
          #  #  xor dword ptr [rsp], 0x1010101
          #  #  mov rax, 0x7361702f6374652f
          #  #  push rax
          #  #  /* call open("rsp", 0, "O_RDONLY") */
          #  #  push 2 /* (SYS_open) */
          #  #  pop rax
          #  #  mov rdi, rsp
          #  #  xor esi, esi /* 0 */
          #  #  cdq /* rdx=0 */
          #  #  syscall
          #  #  /* call sendfile(1, "rax", 0, 2147483647) */
          #  #  push 1
          #  #  pop rdi
          #  #  mov rsi, rax
          #  #  push 0x28 /* (SYS_sendfile) */
          #  #  pop rax
          #  #  mov r10d, 0x7fffffff
          #  #  cdq /* rdx=0 */
          #  #  syscall
          #  #=> nil
          def cat(filename, fd: 1)
            abi = ::Pwnlib::ABI::ABI.syscall
            cat Common.pushstr(filename)
            cat Linux.syscall('SYS_open', abi.stack_pointer, 0, 'O_RDONLY')
            cat Linux.syscall('SYS_sendfile', fd, abi.register_arguments.first, 0, 0x7fffffff)
          end
        end
      end
    end
  end
end
