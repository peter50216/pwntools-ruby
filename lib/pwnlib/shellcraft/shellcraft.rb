# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'singleton'

require 'pwnlib/context'
require 'pwnlib/errors'
require 'pwnlib/logger'

module Pwnlib
  # Implement shellcraft!
  #
  # All shellcode generators are defined under generators/*.
  # While typing +Shellcraft::Generators::I386::Linux.sh+ is too annoying, we define an instance +shellcraft+ in this
  # module, which let user invoke +shellcraft.sh+ directly.
  module Shellcraft
    # Singleton class.
    class Shellcraft
      include ::Singleton

      # All files under generators/ will be required.
      def initialize
        Dir[File.join(__dir__, 'generators', '**', '*.rb')].sort.each do |f|
          require f
        end
      end

      # Will search modules/methods under {Shellcraft::Generators} according to current arch and os.
      # i.e. +Shellcraft::Generators::${arch}::<Common|${os}>.${method}+.
      #
      # With this method, +context.local(arch: 'amd64') { shellcraft.sh }+ will invoke
      # {Shellcraft::Generators::Amd64::Linux#sh}.
      def method_missing(method, *args, **kwargs, &block)
        mod = find_module_for(method)
        return super if mod.nil?

        mod.public_send(method, *args, **kwargs, &block)
      end

      # For +respond_to?+.
      def respond_to_missing?(method, include_private = false)
        return true if find_module_for(method)

        super
      end

      private

      # @return [Module?]
      #   +nil+ for not found.
      def find_module_for(method)
        begin
          arch_module = ::Pwnlib::Shellcraft::Generators.const_get(context.arch.capitalize)
        rescue NameError
          raise ::Pwnlib::Errors::UnsupportedArchError,
                "Can't use shellcraft under architecture #{context.arch.inspect}."
        end
        # try search in Common module
        common_module = arch_module.const_get(:Common)
        return common_module if common_module.singleton_methods.include?(method)

        # search in ${os} module
        os_module = arch_module.const_get(context.os.capitalize)
        return os_module if os_module.singleton_methods.include?(method)

        nil
      end

      include ::Pwnlib::Context
      include ::Pwnlib::Logger
    end
  end
end
