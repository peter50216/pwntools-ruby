# encoding: ASCII-8BIT

require 'pwnlib/abi'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/shellcraft/registers'

::Pwnlib::Shellcraft.define(__FILE__) do |path, argv, envp|
  extend ::Pwnlib::Shellcraft::Registers::ClassMethods
  abi = ::Pwnlib::ABI::LINUX_I386_SYSCALL
  i386 = ::Pwnlib::Shellcraft.instance.i386

  argv = case argv
         when String
           raise ArgumentError, "#{argv.inspect} is not a valid register name" unless register?(argv)
           argv
         when Array
           cat i386.pushstr_array(abi.register_arguments[2], argv)
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
           cat i386.pushstr_array(abi.register_arguments[3], envp.map { |k, v| "#{k}=#{v}" })
           cat ''
           abi.register_arguments[3]
         when Integer, NilClass
           envp.to_i
         end

  unless register?(path)
    cat i386.pushstr(path)
    cat ''
    path = 'esp'
  end
  cat i386.linux.syscalls.syscall('SYS_execve', path, argv, envp)
end
