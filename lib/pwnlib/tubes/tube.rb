# encoding: ASCII-8BIT
require 'pwnlib/timer'
require 'pwnlib/tubes/buffer'

module Pwnlib
  module Tubes
    # Things common to all tubes (sockets, tty, ...)
    class Tube
      BUFSIZE = 4096

      def initialize(timeout: nil)
        @timer = Timer.new(timeout)
        @buffer = Buffer.new
      end

      def recv(num_bytes, timeout: nil)
        return '' if @buffer.empty? && !fillbuffer(timeout: timeout)
        @buffer.get(num_bytes)
      end

      def unrecv(data)
        @buffer.unget(data)
      end

      def recvpred(timeout: nil, &pred)
        raise ArgumentError, 'recvpred with no pred' unless pred
        @timer.countdown(timeout) do
          data = ''
          begin
            until pred.call(data)
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
            @buffer.unget(data)
          end
        end
      end

      def recvn(num_bytes, timeout: nil)
        @timer.countdown(timeout) do
          # TODO(Darkpi): Select!
          fillbuffer while @timer.active? && @buffer.size < num_bytes
          @buffer.size >= num_bytes ? @buffer.get(num_bytes) : ''
        end
      end

      private

      def fillbuffer(timeout: nil)
        data = @timer.countdown(timeout) do
          set_timeout_raw(@timer.timeout)
          recv_raw(BUFSIZE)
        end
        # TODO(Darkpi): Logging.
        @buffer << data if data
        data
      end
    end
  end
end
