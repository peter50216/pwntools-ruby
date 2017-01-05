# encoding: ASCII-8BIT

module Pwnlib
  module Constants
    # A class that includes name and value
    #
    # @note This class `looks like` inherit from {Fixnum}. While {Fixnum} is not inheritable, so there're some hacking methods.
    class Constant
      attr_reader :str, :val
      def initialize(str, val)
        @str = str
        @val = val
      end

      # To looks like inherit from {Fixnum}
      def method_missing(method, *args, &block)
        @val.send(method, *args, &block)
      end

      def is_a?(klass)
        return true if @val.is_a? klass
        super
      end

      # @example
      #   Constant.new('SYS_read', 0) == 0 #=> true
      #   Constant.new('SYS_read', 0) == Constant.new('SYS_read', 0) #=> true
      #   Constant.new('SYS_read', 0) == Constant.new('__NR_read', 0) #=> false
      def ==(other)
        return @str == other.str && @val == other.val if other.is_a? Constant
        return @val == other if other.is_a? Fixnum
        super
      end

      def to_i
        @val
      end

      def to_s
        @str
      end

      def inspect
        format('Constant(%s, %#x)', @str.inspect, @val)
      end
    end
  end
end
