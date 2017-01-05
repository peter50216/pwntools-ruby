# encoding: ASCII-8BIT

module Pwnlib
  module Constants
    # A class that includes name and value
    class Constant < Numeric
      attr_reader :str, :val
      def initialize(str, val)
        @str = str
        @val = val
      end

      def method_missing(method, *args, &block)
        @val.send(method, *args, &block)
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
        format('Constant(%s, 0x%x)', @str.inspect, @val)
      end

      def <=>(other)
        to_i <=> other.to_i
      end
    end
  end
end
