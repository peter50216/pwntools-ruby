# encoding: ASCII-8BIT

require 'dentaku'

require 'pwnlib/context'
require 'pwnlib/constants/constant'

module Pwnlib
  # Module containing constants.
  #
  # @example
  #   context.arch = 'amd64'
  #   Pwnlib::Constants.SYS_read
  #   # => Constant('SYS_read', 0x0)
  module Constants
    class << self
      # To support getting constants like +Pwnlib::Constants.SYS_read+.
      def method_missing(method, *args, &block)
        args.empty? && block.nil? && get_constant(method) || super
      end

      def respond_to_missing?(method, _include_all)
        !get_constant(method).nil?
      end

      # Eval for Constants.
      #
      # @param [String] str
      #   The string to be evaluated.
      #
      # @return [Constant]
      #   The evaluated result.
      #
      # @example
      #   eval('O_CREAT')
      #   => Constant('(O_CREAT)', 0x40)
      #   eval('O_CREAT | O_APPEND')
      #   => Constant('(O_CREAT | O_APPEND)', 0x440)
      def eval(str)
        return str unless str.instance_of?(String)
        begin
          val = calculator.evaluate!(str.strip).to_i
        rescue Dentaku::UnboundVariableError => e
          raise NameError, e.message
        end
        ::Pwnlib::Constants::Constant.new("(#{str})", val)
      end

      private

      def current_arch_key
        [context.os, context.arch]
      end

      ENV_STORE = {} # rubocop:disable Style/MutableConstant
      def current_store
        ENV_STORE[current_arch_key] ||= load_constants(current_arch_key)
      end

      def get_constant(symbol)
        current_store[symbol]
      end

      CALCULATORS = {} # rubocop:disable Style/MutableConstant
      def calculator
        CALCULATORS[current_arch_key] ||= Dentaku::Calculator.new.store(current_store)
      end

      # Small class for instance_eval loaded file.
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

      include ::Pwnlib::Context
    end
  end
end
