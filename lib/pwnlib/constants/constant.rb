# encoding: ASCII-8BIT

require 'pwnlib/util/fiddling'

module Pwnlib
  module Constants
    # A class that includes name and value representing a constant.
    class Constant < Numeric
      attr_reader :str, :val
      def initialize(str, val)
        @str = str
        @val = val
      end

      # We don't need to fall back to super for this, so just disable the lint.
      def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissing
        @val.__send__(method, *args, &block)
      end

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
