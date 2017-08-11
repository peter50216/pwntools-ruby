# encoding: ASCII-8BIT

require 'pwnlib/context'
require 'pwnlib/timer'
require 'pwnlib/tubes/buffer'

module Pwnlib
  module Tubes
    # Things common to all tubes (sockets, tty, ...)
    class Tube
      BUFSIZE = 4096

      # Instantiate an {Pwnlib::Tubes::Tube} object.
      #
      # @param [Float] timeout
      #   Any positive float, indicates timeouts in seconds.
      def initialize(timeout: nil)
        @timer = Timer.new(timeout)
        @buffer = Buffer.new
      end

      # Receives up to +num_bytes+ bytes of data from the tube, and returns as soon as any quantity
      # of data is available.
      #
      # @param [Integer] num_bytes
      #   The maximum number of bytes to receive.
      # @param [Float] timeout
      #   Any positive float, indicates timeouts in seconds.
      #
      # @return [String]
      #   A string containing bytes received from the tube, or +''+ if a timeout occurred while
      #   waiting.
      def recv(num_bytes = nil, timeout: nil)
        return '' if @buffer.empty? && !fillbuffer(timeout: timeout)
        @buffer.get(num_bytes)
      end
      alias read recv

      # Puts the specified data back at the beginning of the receive buffer.
      #
      # @param [String] data
      #   A string to put back.
      def unrecv(data)
        @buffer.unget(data)
      end

      # Receives one byte at a time from the tube, until +pred(bytes)+ evaluates to True.
      #
      # @param [Float] timeout
      #   Any positive float, indicates timeouts in seconds.
      #
      # @yieldparam [String] data
      #   A string data to be validated by +pred+.
      #
      # @yieldreturn [Boolean]
      #   Whether the data passed +pred+.
      #
      # @return [String]
      #   A string containing bytes received from the tube, or +''+ if a timeout occurred while
      #   waiting.
      #
      # @raise [ArgumentError]
      #   If the block is not given.
      def recvpred(timeout: nil)
        raise ArgumentError, 'recvpred with no pred' unless block_given?
        @timer.countdown(timeout) do
          data = ''
          begin
            until yield(data)
              return '' unless @timer.active?

              begin
                # TODO(Darkpi): Some form of binary search to speed up?
                c = recv(1)
              rescue
                return ''
              end

              return '' if c.empty?
              data << c
            end
            data.slice!(0..-1)
          ensure
            unrecv(data)
          end
        end
      end

      # Receives exactly +num_bytes+ bytes.
      # If the request is not satisfied before +timeout+ seconds pass, all data is buffered and an
      # empty string +''+ is returned.
      #
      # @param [Integer] num_bytes
      #   The number of bytes to receive.
      # @param [Float] timeout
      #   Any positive float, indicates timeouts in seconds.
      #
      # @return [String]
      #   A string containing bytes received from the tube, or +''+ if a timeout occurred while
      #   waiting.
      def recvn(num_bytes, timeout: nil)
        @timer.countdown(timeout) do
          # TODO(Darkpi): Select!
          fillbuffer while @timer.active? && @buffer.size < num_bytes
          @buffer.size >= num_bytes ? @buffer.get(num_bytes) : ''
        end
      end

      # DIFF: We return the string that ends the earliest, rather then starts the earliest,
      #       since the latter can't be done greedly. Still, it would be bad to call this
      #       for case with ambiguity.
      #
      # @param [Regexp] regex
      #   A regex to match.
      # @param [Float] timeout
      #   Any positive float, indicates timeouts in seconds.
      #
      def recvuntil(delims, drop: false, timeout: nil)
        delims = Array(delims)
        max_len = delims.map(&:size).max
        @timer.countdown(timeout) do
          data = Buffer.new
          matching = ''
          begin
            while @timer.active?
              begin
                s = recv(1)
              rescue # TODO(Darkpi): QQ
                return ''
              end

              return '' if s.empty?
              matching << s

              sidx = matching.size
              match_len = 0
              delims.each do |d|
                idx = matching.index(d)
                next unless idx
                if idx + d.size <= sidx + match_len
                  sidx = idx
                  match_len = d.size
                end
              end

              if sidx < matching.size
                r = data.get + matching.slice!(0, sidx + match_len)
                r.slice!(-match_len..-1) if drop
                return r
              end

              data << matching.slice!(0...-max_len) if matching.size > max_len
            end
            ''
          ensure
            unrecv(matching)
            unrecv(data)
          end
        end
      end

      # Receive a single line from the tube.
      # A "line" is any sequence of bytes terminated by the byte sequence set in +newline+, which
      # defaults to +"\n"+.
      #
      # @param [Boolean] drop
      #   Whether drop the line ending.
      # @param [Float] timeout
      #   Any positive float, indicates timeouts in seconds.
      #
      # @return [String]
      #   All bytes received over the tube until the first newline is received.
      #   Optionally retains the ending.
      def recvline(drop: false, timeout: nil)
        recvuntil(context.newline, drop: drop, timeout: timeout)
      end
      alias gets recvline

      # Wrapper around +recvpred+, which will return when a regex matches the string in the buffer.
      #
      # @param [Regexp] regex
      #   A regex to match.
      # @param [Float] timeout
      #   Any positive float, indicates timeouts in seconds.
      #
      # @return [String]
      #   A string containing bytes received from the tube, or +''+ if a timeout occurred while
      #   waiting.
      def recvregex(regex, timeout: nil)
        recvpred(timeout: timeout) { |data| data =~ regex }
      end

      # Sends data
      #
      # @param [String] data
      #   The +data+ string to send.
      def send(data)
        send_raw(data.to_s)
      end
      alias write send

      # Sends data with +context.newline+.
      #
      # @param [String] data
      #   The +data+ string to send.
      def sendline(data)
        send_raw(data.to_s + context.newline)
      end
      alias puts sendline

      # Does simultaneous reading and writing to the tube. In principle this just connects the tube
      # to standard in and standard out.
      def interact
        $stdout.write(@buffer.get)
        until io.closed?
          rs, = IO.select([$stdin, io])
          if rs.include?($stdin)
            s = $stdin.readpartial(BUFSIZE)
            io.write(s)
          end
          if rs.include?(io)
            s = io.readpartial(BUFSIZE)
            $stdout.write(s)
          end
        end
      end

      private

      def fillbuffer(timeout: nil)
        data = @timer.countdown(timeout) do
          self.timeout_raw = @timer.timeout
          recv_raw(BUFSIZE)
        end
        # TODO(Darkpi): Logging.
        @buffer << data if data
        data
      end

      def send_raw(_data); raise NotImplementedError, 'Not implemented'
      end

      def recv_raw(_size); raise NotImplementedError, 'Not implemented'
      end

      def timeout_raw=(_timeout); raise NotImplementedError, 'Not implemented'
      end

      include Context
    end
  end
end
