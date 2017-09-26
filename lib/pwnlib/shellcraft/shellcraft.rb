# encoding: ASCII-8BIT

require 'singleton'

require 'pwnlib/constants/constant'
require 'pwnlib/constants/constants'
require 'pwnlib/logger'
require 'pwnlib/context'
require 'pwnlib/shellcraft/registers'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/packing'

module Pwnlib
  # Implement shellcraft!
  #
  # All shellcode generators are defined under generators/*.
  # While typing +Shellcraft::Generators::I386::Linux.sh+ is too annoying, we define an instance +shellcraft+ in this
  # module, which let user can invoke +shellcraft.sh+ directly.
  module Shellcraft
    class Shellcraft
      include ::Singleton

      # Require all files under shellcraft/generators/.
      def initialize
        Dir[File.join(__dir__, 'generators', '**', '*.rb')].each do |f|
          require f
        end
      end

      # Search module/methods under {Shellcraft::Generators} according to current arch and os.
      # i.e. +Shellcraft::Generators::${arch}::<Common|${os}>.${method}+.
      def method_missing(method, *args, &block)
        begin
          arch_module = ::Pwnlib::Shellcraft::Generators.const_get(context.arch.capitalize)
        rescue NameError # No proper module found
          log.error("Can't use shellcraft under architecture #{context.arch.inspect}.")
          return super
        end
        # try search in Common module
        common_module = arch_module.const_get(:Common)
        return common_module.public_send(method, *args, &block) if common_module.singleton_methods.include?(method)
        os_module = arch_module.const_get(context.os.capitalize)
        return os_module.public_send(method, *args, &block) if os_module.singleton_methods.include?(method)
        super
      end

      include ::Pwnlib::Context
      include ::Pwnlib::Logger
    end
  end
end
