#encoding: ASCII-8BIT

module Pwnlib
  module Constants
    class Constant
      def initialize(str, val)
        @str = str
        @val = val
      end

      def to_s
        @str
      end

      def inspect
        format("Constant(%s, %#x)", @str.inspect, @val)
      end
    end
  end
end
