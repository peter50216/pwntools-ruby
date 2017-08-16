# encoding: ASCII-8BIT

require 'socket'

require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # Socket!
    class Sock < Tube
      # Instantiate a {Pwnlib::Tubes::Sock} object.
      #
      # @param [String] host
      #   The host to connect.
      # @param [Integer] port
      #   The port to connect.
      def initialize(host, port)
        super()
        @sock = TCPSocket.new(host, port)
        @sock.binmode
        @timeout = nil
        @closed = { recv: false, send: false }
      end

      def io
        @sock
      end
      alias sock io

      # Close the TCPSocket.
      def close
        @closed[:recv] = @closed[:send] = true
        @sock.close
      end

      private

      # TODO(hh): Disallows further read/write using shutdown system call in +sock+.
      def shutdown(direction)
        @closed[direction] = true
      end

      def timeout_raw=(timeout)
        @timeout = timeout == :forever ? nil : timeout
      end

      def send_raw(data)
        raise EOFError if @closed[:send]
        begin
          @sock.write(data)
        rescue Errno::EPIPE, Errno::ECONNRESET, Errno::ECONNREFUSED
          shutdown(:send)
          raise EOFError
        end
      end

      def recv_raw(size)
        raise EOFError if @closed[:recv]
        begin
          rs, = IO.select([@sock], [], [], @timeout)
          return if rs.nil?
          return @sock.readpartial(size)
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ECONNABORTED, EOFError
          shutdown(:recv)
          raise EOFError
        end
      end
    end
  end
end
