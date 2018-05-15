# encoding: ASCII-8BIT

require 'rubyserial'

require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # Serial Connections
    class SerialTube < Tube
      # Instantiate a {Pwnlib::Tubes::SerialTube} object.
      #
      # @param [String] port
      #   A device name for rubyserial to open, e.g. /dev/ttypUSB0
      # @param [Integer] baudrate
      #   Baud rate.
      # @param [Boolean] convert_newlines
      #   If +true+, will convert local +context.newline+ to +"\\r\\n"+ for remote
      # @param [Integer] bytesize
      #   Serial character byte size. The '8' in '8N1'.
      # @param [Symbol] parity
      #   Serial character parity. The 'N' in '8N1'.
      def initialize(port = nil, baudrate = 115_200,
                     convert_newlines = true,
                     bytesize = 8, parity = :none)
        super()

        # go hunting for a port
        port = Dir.glob('/dev/tty.usbserial*').first if port.nil?
        port = '/dev/ttyUSB0' if port.nil?

        @convert_newlines = convert_newlines
        @conn = Serial.new(port, baudrate, bytesize, parity)
        @timer = Timer.new
      end

      # Closes the active connection
      def close
        @conn.close if @conn
        @conn = nil
      end

      # Gets bytes over the serial connection until some bytes are received, or
      # +@timeout+ has passed. It is an error for it to return no data in less
      # than +@timeout+ seconds. It is ok for it to return some data in less
      # time.
      #
      # @param [Integer] numbytes
      #   An upper limit on the number of bytes to get.
      #
      # @return [String]
      #   A string containing read bytes.
      #
      # @!macro raise_eof
      def recv_raw(numbytes)
        raise EOFError if @conn.nil?

        @timer.countdown do
          data = ''
          begin
            while @timer.active?
              data += @conn.read(numbytes - data.length)
              break if data.length >= numbytes
              sleep 0.1
            end
            # TODO: should we reverse @convert_newlines here?
            return data
          rescue RubySerial::Error
            close
            raise EOFError
          end
        end
      end

      # Sends bytes over the serial connection. This call will block until all the bytes are sent or an error occurs.
      #
      # @param [String] data
      #   A string of the bytes to send.
      #
      # @return [Integer]
      #   The number of bytes successfully written.
      #
      # @!macro raise_eof
      def send_raw(data)
        raise EOFError if @conn.nil?

        data.gsub!(context.newline, "\r\n") if @convert_newlines
        begin
          return @conn.write(data)
        rescue RubySerial::Error
          close
          raise EOFError
        end
      end

      # Sets the +timeout+ to use for subsequent +recv_raw+ calls.
      #
      # @param [Integer] timeout
      def timeout_raw=(timeout)
        @timer.timeout = timeout
      end

      # Checks to see if the serial connection is active.
      #
      # @return [Boolean]
      #   +true+ iff the connection has been created and not closed.
      def connected_raw
        return false if @conn.nil?
        return false if @conn.closed?
        true
      end

      # Not Implemented.
      def fileno
        raise 'A closed serialtube does not have a file number' if @conn.closed?
        raise 'Not Implemented by rubyserial'
      end
    end
  end
end
