# encoding: ASCII-8BIT

require 'socket'

require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    class Sock < Tube
      def initialize(host, port)
        super()
        @sock = TCPSocket.new(host, port)
        @sock.binmode
        @timeout = :forever
      end

      def set_timeout_raw(timeout)
        @timeout = timeout == :forever ? nil : timeout
      end

      def send_raw(data)
        @sock.write(data)
      end

      def recv_raw(data)
        rs, = IO.select([@sock], [], [], @timeout)
        return if rs.nil?
        @sock.readpartial(BUFSIZE)
      end
    end
  end
end
