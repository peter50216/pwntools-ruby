# encoding: ASCII-8BIT

require 'socket'

require 'pwnlib/errors'
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
      # @param [Float?] timeout
      #   See {Pwnlib::Tubes::Tube#initialize}.
      def initialize(host, port, timeout: nil)
        super(timeout: timeout)
        @sock = TCPSocket.new(host, port)
        @sock.binmode
        @timeout = nil
        @closed = { recv: false, send: false }
      end

      def io
        @sock
      end
      alias sock io

      # Close the TCPSocket if no arguments passed.
      # Or close the direction in +sock+.
      #
      # @param [:both, :recv, :read, :send, :write] direction
      #   * Close the TCPSocket if +:both+ or no arguments passed.
      #   * Disallow further read in +sock+ if +:recv+ or +:read+ passed.
      #   * Disallow further write in +sock+ if +:send+ or +:write+ passed.
      #
      # @diff In pwntools-python, method +shutdown(direction)+ is for closing socket one side,
      #   +close()+ is for closing both side. We merge these two methods into one here.
      def close(direction = :both)
        case direction
        when :both
          return if @sock.closed?
          @closed[:recv] = @closed[:send] = true
          @sock.close
        when :recv, :read
          shutdown(:recv)
        when :send, :write
          shutdown(:send)
        else
          raise ArgumentError, 'Only allow :both, :recv, :read, :send and :write passed'
        end
      end

      private

      def shutdown(direction)
        return if @closed[direction]
        @closed[direction] = true

        if direction.equal?(:recv)
          @sock.close_read
        elsif direction.equal?(:send)
          @sock.close_write
        end
      end

      def timeout_raw=(timeout)
        @timeout = timeout == :forever ? nil : timeout
      end

      def send_raw(data)
        raise ::Pwnlib::Errors::EndOfTubeError if @closed[:send]
        begin
          @sock.write(data)
        rescue Errno::EPIPE, Errno::ECONNRESET, Errno::ECONNREFUSED
          shutdown(:send)
          raise ::Pwnlib::Errors::EndOfTubeError
        end
      end

      def recv_raw(size)
        raise ::Pwnlib::Errors::EndOfTubeError if @closed[:recv]
        begin
          rs, = IO.select([@sock], [], [], @timeout)
          return if rs.nil?
          return @sock.readpartial(size)
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ECONNABORTED, EOFError
          shutdown(:recv)
          raise ::Pwnlib::Errors::EndOfTubeError
        end
      end
    end
  end
end
