# encoding: ASCII-8BIT

require 'pwnlib/abi'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/shellcraft/registers'

# Execute a different process.
#
# @param [String] path
#   Can be either a absolute path or a register name.
# @param [String, Array<String>, Integer, NilClass] argv
#   If +argv+ is a +String+, it would be seen as a register.
#   If +Array<String>+, works like normal arguments array.
#   If +Integer+, take it as a pointer adrress. (same as
#   +nil+ if zero is given.
#   If +NilClass+, use NULL pointer.
# @param [String, Hash<String => String>, Integer, NilClass] envp
#   +String+ for register name.
#   If +envp+ is a +Hash<String => String>+, it will be
#   convert into the environ form (i.e. key=value).
#   If +Integer+, take it as a pointer adrress. (same as
#   +nil+ if zero is given.
#   If +NilClass+ is given, use NULL pointer.
# @example
#   shellcraft.x86.linux.syscalls.execve('/bin/sh', ['sh'], {PWD: '.'})
# @diff
#   I think it's better to always specific +path, argv, envp+
#   instead use default value since this is a basic function.
::Pwnlib::Shellcraft.define(__FILE__) do |path, argv, envp|
  extend ::Pwnlib::Shellcraft::Registers::ClassMethods
  abi = ::Pwnlib::ABI::ABI.syscall
  shellcraft = ::Pwnlib::Shellcraft.instance

  argv = case argv
         when String
           raise ArgumentError, "#{argv.inspect} is not a valid register name" unless register?(argv)
           argv
         when Array
           cat shellcraft.pushstr_array(abi.register_arguments[2], argv)
           cat ''
           abi.register_arguments[2]
         when Integer, NilClass
           argv.to_i
         end

  envp = case envp
         when String
           raise ArgumentError, "#{envp.inspect} is not a valid register name" unless register?(envp)
           envp
         when Hash
           cat shellcraft.pushstr_array(abi.register_arguments[3], envp.map { |k, v| "#{k}=#{v}" })
           cat ''
           abi.register_arguments[3]
         when Integer, NilClass
           envp.to_i
         end

  unless register?(path)
    cat shellcraft.pushstr(path)
    cat ''
    path = abi.stack_register
  end
  cat shellcraft.x86.linux.syscalls.syscall('SYS_execve', path, argv, envp)
end
