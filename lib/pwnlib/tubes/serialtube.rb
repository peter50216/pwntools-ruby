# encoding: ASCII-8BIT

require 'rubyserial'

require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # Serial Connections
    class SerialTube < Tube
      def initialize(port = nil, baudrate = 115_200,
                     convert_newlines = true,
                     bytesize = 8, parity = :none)
        super()

        # go hunting for a port
        port = Dir.glob('/dev/tty.usbserial*')[0] if port.nil?
        port = '/dev/ttyUSB0' if port.nil?

        @convert_newlines = convert_newlines
        @conn = Serial.new(port, baudrate, bytesize, parity)
      end

      def close
        @conn.close if @conn
        @conn = nil
      end

      # Implementation of the methods required for tube

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

      def settimeout_raw
        raise 'Not Implemented by rubyserial'
      end

      def can_recv_raw
        raise 'Not Implemented by rubyserial'
      end

      def connected_raw
        return false if @conn.nil?
        return false if @conn.closed?
        true
      end

      def fileno
        raise 'A closed serialtube does not have a file number' if @conn.closed?
        raise 'Not Implemented by rubyserial'
      end

      def shutdown_raw
        close
      end
    end
  end
end
