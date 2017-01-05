# encoding: ASCII-8BIT

require 'pwnlib/context'
require 'pwnlib/constants/constant'

module Pwnlib
  # Module containing constants
  # @example
  #   context.arch = 'amd64'
  #   Pwnlib::Constants.SYS_read
  #   # => Constant('SYS_read', 0x0)
  module Constants
    # @note Do not create and call instance method here. Instead, call module method on {Constants}.
    module ClassMethod
      include ::Pwnlib::Context
      ENV_STORE = {}
      def method_missing(method, *args)
        args.empty? && get_constant(method) || super
      end

      def eval(str)
        return str unless str.instance_of?(String)
        # TODO(david942j): safeeval
        const = get_constant(str.strip.to_sym)
        ::Pwnlib::Constants::Constant.new("(#{str})", const.val)
      end

      private

      def current_arch_key
        [context.os, context.arch]
      end

      def current_store
        ENV_STORE[current_arch_key] ||= load_constants(current_arch_key)
      end

      def get_constant(symbol)
        current_store[symbol]
      end

      # Small class for instance_eval loaded file
      class ConstantBuilder
        attr_reader :tbl
        def initialize
          @tbl = {}
        end

        def const(sym, val)
          @tbl[sym.to_sym] = Constant.new(sym.to_s, val)
        end
      end

      def load_constants((os, arch))
        filename = File.join(__dir__, os, "#{arch}.rb")
        return {} unless File.exist?(filename)
        ConstantBuilder.new.tap do |c|
          c.instance_eval(IO.read(filename))
        end.tbl
      end
    end

    extend ClassMethod
  end
end
