# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/x86/common/pushstr'
require 'pwnlib/shellcraft/generators/x86/linux/linux'
require 'pwnlib/shellcraft/generators/x86/linux/syscall'
require 'pwnlib/util/packing'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # Sleep for a specified number of seconds.
          #
          # @param [Float] seconds
          #   The seconds to sleep.
          #
          # @example
          #   context.arch = :amd64
          #   puts shellcraft.sleep(1)
          #   #  /* push "\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" */
          #   #  push 1
          #   #  dec byte ptr [rsp]
          #   #  push 1
          #   #  /* call nanosleep("rsp", 0) */
          #   #  push 0x23 /* (SYS_nanosleep) */
          #   #  pop rax
          #   #  mov rdi, rsp
          #   #  xor esi, esi /* 0 */
          #   #  syscall
          #   #  add rsp, 16 /* recover rsp */
          #   #=> nil
          #
          # @note
          #   Syscall +nanosleep+ accepts a data pointer as argument, the stack will be used for putting the data
          #   needed. The generated assembly will use sizeof(struct timespec) = 16 bytes for putting data.
          def sleep(seconds)
            # pushes the data onto stack
            tv_sec = seconds.to_i
            tv_nsec = ((seconds - tv_sec) * 1e9).to_i
            data = ::Pwnlib::Util::Packing.p64(tv_sec) + ::Pwnlib::Util::Packing.p64(tv_nsec)
            cat Common.pushstr(data, append_null: false)
            sp = ::Pwnlib::ABI::ABI.default.stack_pointer
            cat Linux.syscall('SYS_nanosleep', sp, 0)
            cat "add #{sp}, 16 /* recover #{sp} */"
          end
        end
      end
    end
  end
end
