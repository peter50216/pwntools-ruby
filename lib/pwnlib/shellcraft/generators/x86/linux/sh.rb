# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/x86/linux/execve'
require 'pwnlib/shellcraft/generators/x86/linux/linux'

module Pwnlib
  module Shellcraft
    module Generators
      module X86
        module Linux
          module_function

          # Get shell!
          #
          # @param [Boolean, Array<String>] argv
          #   Arguments of +argv+ when calling +execve+.
          #   If +true+ is given, use +['sh']+.
          #   If +Array<String>+ is given, use it as arguments array.
          #
          # @note Null pointer is always used as +envp+.
          #
          # @diff
          #   By default, this method calls +execve('/bin///sh', 0, 0)+, which is different from pwntools-python:
          #   +execve('/bin///sh', ['sh'], 0)+.
          def sh(argv: false)
            argv = case argv
                   when true then ['sh']
                   when false then 0
                   else argv
                   end
            cat execve('/bin///sh', argv, 0)
          end
        end
      end
    end
  end
end
