# encoding: ASCII-8BIT

require 'pwnlib/util/fiddling'

module Pwnlib
  module Constants
    # A class that includes name and value representing a constant.
    # This class works like an integer, and support operations with integers.
    #
    # @example
    #   a = Pwnlib::Constants::Constant.new('a', 0x3)
    #   #=> Constant("a", 0x3)
    #   [a + 1, 2 * a, a | 6, a == 3, 0 > a]
    #   #=> [4, 6, 7, true, false]
    class Constant < Numeric
      # @return [String]
      attr_reader :str

      # @return [Integer]
      attr_reader :val

      # @param [String] str
      # @param [Integer] val
      def initialize(str, val)
        @str = str
        @val = val
      end

      # We don't need to fall back to super for this, so just disable the lint.
      # rubocop:disable Style/MethodMissingSuper
      def method_missing(method, *args, &block)
        @val.__send__(method, *args, &block)
      end
      # rubocop:enable Style/MethodMissingSuper

      def respond_to_missing?(method, include_all)
        @val.respond_to?(method, include_all)
      end

      def coerce(other)
        [other.to_i, to_i]
      end

      def to_i
        @val
      end

      def to_s
        @str
      end

      def inspect
        format('Constant(%p, %s)', @str, ::Pwnlib::Util::Fiddling.hex(@val))
      end

      def <=>(other)
        to_i <=> other.to_i
      end
    end
  end
end
