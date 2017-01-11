# encoding: ASCII-8BIT

module Pwnlib
  module Tubes
    # Buffer that support deque-like string operations.
    class Buffer
      def initialize
        @data = []
        @size = 0
      end

      attr_reader :size
      alias length size

      def empty?
        size.zero?
      end

      # Python __contains__ and index is only correct with single-char input, which doesn't seems to
      # be useful, and they're not used anywhere too. Just ignore them for now.

      def add(data)
        case data
        when Buffer
          @data.concat(data.data)
        else
          data = data.to_s.dup
          return if data.empty?
          @data << data
        end
        @size += data.size
        self
      end
      alias << add

      def unget(data)
        case data
        when Buffer
          @data.unshift(*data.data)
        else
          data = data.to_s.dup
          return if data.empty?
          @data.unshift(data)
        end
        @size += data.size
        self
      end

      def get(n = nil)
        if n.nil? || n >= size
          data = @data.join
          @size = 0
          @data = []
        else
          have = 0
          idx = 0
          while have < n
            have += @data[idx].size
            idx += 1
          end
          data = @data.slice!(0...idx).join
          if have > n
            extra = data.slice!(n..-1)
            @data.unshift(extra)
          end
          @size -= n
        end
        data
      end

      protected

      attr_reader :data
    end
  end
end
