# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'socket'

require 'pwnlib/errors'
require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # Socket!
    class Sock < Tube
      attr_reader :sock # @return [TCPSocket] The socket object.

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
        @closed = { read: false, write: false }
      end

      # Close the TCPSocket if no arguments passed.
      # Or close the direction in +sock+.
      #
      # @param [:both, :recv, :read, :send, :write] direction
      #   * Close the TCPSocket if +:both+ or no arguments passed.
      #   * Disallow further read in +sock+ if +:recv+ or +:read+ passed.
      #   * Disallow further write in +sock+ if +:send+ or +:write+ passed.
      #
      # @return [void]
      #
      # @diff In pwntools-python, method +shutdown(direction)+ is for closing socket one side,
      #   +close()+ is for closing both side. We merge these two methods into one here.
      def close(direction = :both)
        if direction == :both
          return if @sock.closed?

          @closed[:read] = @closed[:write] = true
          @sock.close
        else
          shutdown(*normalize_direction(direction))
        end
      end

      private

      alias io_out sock

      def shutdown(direction)
        return if @closed[direction]

        @closed[direction] = true

        if direction.equal?(:read)
          @sock.close_read
        elsif direction.equal?(:write)
          @sock.close_write
        end
      end

      def timeout_raw=(timeout)
        @timeout = timeout
      end

      def send_raw(data)
        raise ::Pwnlib::Errors::EndOfTubeError if @closed[:write]

        begin
          @sock.write(data)
        rescue Errno::EPIPE, Errno::ECONNRESET, Errno::ECONNREFUSED
          shutdown(:write)
          raise ::Pwnlib::Errors::EndOfTubeError
        end
      end

      def recv_raw(size)
        raise ::Pwnlib::Errors::EndOfTubeError if @closed[:read]

        begin
          rs, = IO.select([@sock], [], [], @timeout)
          return if rs.nil?

          @sock.readpartial(size)
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ECONNABORTED, EOFError
          shutdown(:read)
          raise ::Pwnlib::Errors::EndOfTubeError
        end
      end
    end
  end
end
