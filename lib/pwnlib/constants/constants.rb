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
    module ClassMethods
      include ::Pwnlib::Context
      ENV_STORE = {} # rubocop:disable Style/MutableConstant
      # Try getting constants when method missing
      def method_missing(method, *args, &block)
        args.empty? && block.nil? && get_constant(method) || super
      end

      def respond_to_missing?(method, _include_all)
        !get_constant(method).nil?
      end

      # Eval for Constants
      #
      # @param [String] str
      #   The string to be evaluate.
      #
      # @return [Constant]
      #   The evaluate result.
      #
      # @example
      #   eval('O_CREAT')
      #   => Constant('(O_CREAT)', 0x40)
      #
      # @todo(david942j): Support eval('O_CREAT | O_APPEND') (i.e. safeeval)
      def eval(str)
        return str unless str.instance_of?(String)
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
        builder = ConstantBuilder.new
        builder.instance_eval(IO.read(filename))
        builder.tbl
      end
    end

    extend ClassMethods
  end
end
