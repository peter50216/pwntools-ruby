# encoding: ASCII-8BIT

require 'rubyserial'

require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # Serial Connections
    class SerialTube < Tube
      def initialize(port = nil, baudrate: 115_200,
                     convert_newlines: true,
                     bytesize: 8, parity: :none)
        super()

        # go hunting for a port
        port || port = Dir.glob('/dev/tty.usbserial*')[0]
        port || port = '/dev/ttyUSB0'

        @convert_newlines = convert_newlines
        @conn = Serial.new(port, baudrate, bytesize, parity)
      end

      def close
        @conn.close if @conn
        @conn = nil
      end

      # Implementation of the methods required for tube
      private

      # Non-blocking, will happily return less than numbytes
      # if that's all that's available
      def recv_raw(numbytes)
        raise EOFError if @conn.nil?

        begin
          return @conn.read(numbytes)
        rescue RubySerial::Error
          shutdown(:recv)
          raise EOFError
        end
      end

      # Writes data. Returns number of bytes written.
      def send_raw(data)
        raise EOFError if @conn.nil?

        data.gsub!(/\n/, "\r\n") if @convert_newlines
        begin
          return @conn.write(data)
        rescue RubySerial::Error
          shutdown(:send)
          raise EOFError
        end
      end

      def timeout_raw=(timeout)
        # XXX: We can't do it, just ignoring
        # In particular, rubyserial doesn't do timeouts, it always returns
        # immediately. Fortunately, the Tube superclass has a fallback timer
        # which covers our needs.
      end
    end
  end
end
