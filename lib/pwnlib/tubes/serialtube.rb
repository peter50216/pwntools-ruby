# encoding: ASCII-8BIT

require 'rubyserial'

require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # @!macro [new] raise_eof
    #   @raise [Pwnlib::Errors::EndOfTubeError]
    #     If the request is not satisfied when all data is received.

    # Serial Connections
    class SerialTube < Tube
      # Instantiate a {Pwnlib::Tubes::SerialTube} object.
      #
      # @param [String] port
      #   A device name for rubyserial to open, e.g. /dev/ttypUSB0
      # @param [Integer] baudrate
      #   Baud rate.
      # @param [Boolean] convert_newlines
      #   If +true+, convert any +context.newline+s to +"\\r\\n"+ before
      #   sending to remote. Has no effect on bytes received.
      # @param [Integer] bytesize
      #   Serial character byte size. The '8' in '8N1'.
      # @param [Symbol] parity
      #   Serial character parity. The 'N' in '8N1'.
      def initialize(port = nil, baudrate: 115_200,
                     convert_newlines: true,
                     bytesize: 8, parity: :none)
        super()

        # go hunting for a port
        port ||= Dir.glob('/dev/tty.usbserial*').first
        port ||= '/dev/ttyUSB0'

        @convert_newlines = convert_newlines
        @conn = Serial.new(port, baudrate, bytesize, parity)
        @serial_timer = Timer.new
      end

      # Closes the active connection
      def close
        @conn.close if @conn && !@conn.closed?
        @conn = nil
      end

      # Implementation of the methods required for tube
      private

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
        raise ::Pwnlib::Errors::EndOfTubeError if @conn.nil?

        @serial_timer.countdown do
          data = ''
          begin
            while @serial_timer.active?
              data += @conn.read(numbytes - data.length)
              break unless data.empty?
              sleep 0.1
            end
            # XXX(JonathanBeverley): should we reverse @convert_newlines here?
            return data
          rescue RubySerial::Error
            close
            raise ::Pwnlib::Errors::EndOfTubeError
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
        raise ::Pwnlib::Errors::EndOfTubeError if @conn.nil?

        data.gsub!(context.newline, "\r\n") if @convert_newlines
        begin
          return @conn.write(data)
        rescue RubySerial::Error
          close
          raise ::Pwnlib::Errors::EndOfTubeError
        end
      end

      # Sets the +timeout+ to use for subsequent +recv_raw+ calls.
      #
      # @param [Float] timeout
      def timeout_raw=(timeout)
        @serial_timer.timeout = timeout
      end
    end
  end
end
