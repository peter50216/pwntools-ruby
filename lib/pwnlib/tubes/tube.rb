# encoding: ASCII-8BIT
require 'pwnlib/timer'
require 'pwnlib/tubes/buffer'

module Pwnlib
  module Tubes
    # Things common to all tubes (sockets, tty, ...)
    class Tube
      BUFSIZE = 4096

      def initialize(timeout: nil)
        @timer = Timer.new(self, timeout)
        @buffer = Buffer.new
      end

      def readpartial(num_bytes, timeout: nil)
        return '' if @buffer.empty? && !fillbuffer(timeout: timeout)
        @buffer.get(num_bytes)
      end
      alias recv readpartial

      def unrecv(data)
        @buffer.unget(data)
      end

      private

      def fillbuffer(timeout: nil)
        data = @timer.local(timeout) { recv_raw(BUFSIZE) }
        # TODO: Logging.
        @buffer << data if data
        data
      end
    end
  end
end
