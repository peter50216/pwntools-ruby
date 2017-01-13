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
#   shellcraft.amd64.linux.execve('/bin/sh', ['sh'], {PWD: '.'})
# @diff
#   I think it's better to always specific +path, argv, envp+
#   instead use default value since this is a basic function.
::Pwnlib::Shellcraft.define('amd64.linux.execve') do |path, argv, envp|
  extend ::Pwnlib::Shellcraft::Registers::ClassMethods
  abi = ::Pwnlib::ABI::LINUX_AMD64_SYSCALL
  amd64 = ::Pwnlib::Shellcraft.instance.amd64

  argv = case argv
         when String
           raise ArgumentError, "#{argv.inspect} is not a valid register name" unless register?(argv)
           argv
         when Array
           cat amd64.pushstr_array(abi.register_arguments[2], argv)
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
           cat amd64.pushstr_array(abi.register_arguments[3], envp.map { |k, v| "#{k}=#{v}" })
           cat ''
           abi.register_arguments[3]
         when Integer, NilClass
           envp.to_i
         end

  unless register?(path)
    cat amd64.pushstr(path)
    cat ''
    path = 'rsp'
  end
  cat amd64.linux.syscall('SYS_execve', path, argv, envp)
end
