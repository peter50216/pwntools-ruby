# encoding: ASCII-8BIT

module Pwnlib
  module Tubes
    # Buffer that support deque-like string operations.
    class Buffer
      # Instantiate a {Pwnlib::Tubes::Buffer} object.
      def initialize
        @data = []
        @size = 0
      end

      attr_reader :size
      alias length size

      # Check whether the buffer is empty.
      #
      # @return [Boalean]
      #   Returns true if contains no elements.
      def empty?
        size.zero?
      end

      # Python __contains__ and index is only correct with single-char input, which doesn't seems to
      # be useful, and they're not used anywhere either. Just ignore them for now.

      # Adds data to the buffer.
      #
      # @param [String] data
      #   Data to add.
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

      # Places data at the front of the buffer.
      #
      # @param [String] data
      #   Data to place at the beginning of the buffer.
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

      # Retrieves bytes from the buffer.
      #
      # @param [Integer] n
      #   Maximum number of bytes to fetch.
      #
      # @return [String]
      #   Data as string.
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
