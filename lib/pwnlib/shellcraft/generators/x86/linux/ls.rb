# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/x86/common/pushstr'
require 'pwnlib/shellcraft/generators/x86/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/syscall'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # List files.
          #
          # @param [String] dir
          #   The relative path to be listed.
          #
          # @example
          #  context.arch = 'amd64'
          #  puts shellcraft.ls
          #  #   /* push ".\x00" */
          #  #   push 0x2e
          #  #   /* call open("rsp", 0, 0) */
          #  #   push 2 /* (SYS_open) */
          #  #   pop rax
          #  #   mov rdi, rsp
          #  #   xor esi, esi /* 0 */
          #  #   cdq /* rdx=0 */
          #  #   syscall
          #  #   /* call getdents("rax", "rsp", 4096) */
          #  #   mov rdi, rax
          #  #   push 0x4e /* (SYS_getdents) */
          #  #   pop rax
          #  #   mov rsi, rsp
          #  #   xor edx, edx
          #  #   mov dh, 0x1000 >> 8
          #  #   syscall
          #  #   /* call write(1, "rsp", "rax") */
          #  #   push 1
          #  #   pop rdi
          #  #   mov rsi, rsp
          #  #   mov rdx, rax
          #  #   push 1 /* (SYS_write) */
          #  #   pop rax
          #  #   syscall
          #  #=> nil
          #
          # @note
          #   This shellcode will output the binary data returned by syscall +getdents+.
          #   Use {Pwnlib::Util::Getdents.parse} to parse the output.
          def ls(dir = '.')
            abi = ::Pwnlib::ABI::ABI.syscall
            cat Common.pushstr(dir)
            cat Linux.syscall('SYS_open', abi.stack_pointer, 0, 0)
            # In x86, return value register is same as sysnr register.
            ret = abi.register_arguments.first
            # XXX(david942j): Will fixed size 0x1000 be an issue?
            cat Linux.syscall('SYS_getdents', ret, abi.stack_pointer, 0x1000) # getdents(fd, buf, sz)

            # Just write all the shits out
            cat Linux.syscall('SYS_write', 1, abi.stack_pointer, ret)
          end
        end
      end
    end
  end
end
