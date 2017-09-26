# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/x86/common/pushstr'
require 'pwnlib/shellcraft/generators/x86/common/pushstr_array'
require 'pwnlib/shellcraft/generators/x86/linux/linux'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          # Execute a different process.
          #
          # @param [String] path
          #   Can be either an absolute path or a register's name.
          # @param [String, Array<String>, Integer, nil] argv
          #   If +argv+ is a +String+, it would be seen as a register.
          #   If +Array<String>+, works like normal arguments array.
          #   If +Integer+, take it as a pointer adrress. (same as +nil+ if zero is given.)
          #   If +nil+, use NULL pointer.
          # @param [String, Hash{#to_s => #to_s}, Integer, nil] envp
          #   +String+ for register name.
          #   If +envp+ is a +Hash+, it will be converted into the environ form (i.e. key=value).
          #   If +Integer+, take it as a pointer address (same as +nil+ if zero is given).
          #   If +nil+ is given, use NULL pointer.
          #
          # @example
          #   execve('/bin/sh', ['sh'], {PWD: '.'})
          #
          # @diff
          #   Parameters have no default values since this is a basic function.
          def execve(path, argv, envp)
            abi = ::Pwnlib::ABI::ABI.syscall
            argv = case argv
                   when String
                     raise ArgumentError, "#{argv.inspect} is not a valid register name" unless register?(argv)
                     argv
                   when Array
                     cat Common.pushstr_array(abi.register_arguments[2], argv)
                     cat ''
                     abi.register_arguments[2]
                   when Integer, nil
                     argv.to_i
                   end

            envp = case envp
                   when String
                     raise ArgumentError, "#{envp.inspect} is not a valid register name" unless register?(envp)
                     envp
                   when Hash
                     cat Common.pushstr_array(abi.register_arguments[3], envp.map { |k, v| "#{k}=#{v}" })
                     cat ''
                     abi.register_arguments[3]
                   when Integer, nil
                     envp.to_i
                   end

            unless register?(path)
              cat Common.pushstr(path)
              cat ''
              path = abi.stack_pointer
            end
            cat Linux.syscall('SYS_execve', path, argv, envp)
          end
        end
      end
    end
  end
end
