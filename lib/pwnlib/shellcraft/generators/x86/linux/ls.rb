# encoding: ASCII-8BIT

require 'pwnlib/abi'

# List files.
#
# @param [String] dir
#   The relative path to be listed.
#
# @note
#   This shellcode will output the binary data returns by syscall +getdents+.
#   Use {Pwnlib::Util::Getdents.parse} to parse the output.
::Pwnlib::Shellcraft.define(__FILE__) do |dir = '.'|
  abi = ::Pwnlib::ABI::ABI.syscall
  cat shellcraft.pushstr(dir)
  cat shellcraft.x86.linux.syscalls.syscall('SYS_open', abi.stack_pointer, 0, 0)
  # In x86, return value register is same as sysnr register.
  ret = abi.register_arguments.first
  # XXX(david942j): Will fixed size 0x1000 be an issue?
  cat shellcraft.x86.linux.syscalls.syscall('SYS_getdents', ret, abi.stack_pointer, 0x1000) # getdents(fd, buf, sz)

  # Just write all the shits out
  cat shellcraft.x86.linux.syscalls.syscall('SYS_write', 1, abi.stack_pointer, ret)
end
