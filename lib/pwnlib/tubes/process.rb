# encoding: ASCII-8BIT

require 'open3'
require 'pty'

require 'pwnlib/errors'
require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # Launch a process.
    class Process < Tube
      # Instantiate a {Pwnlib::Tubes::Process} object.
      #
      # @param [Array<String>, String] argv
      #   List of arguments to pass to the spawned process.
      #
      # @option opts [Symbol] in (:pipe)
      #   What kind of io should be used for stdin.
      #   Candidates are: `:pipe`, `:pty`.
      # @option opts [Symbol] out (:pipe)
      #   What kind of io should be used for stdout.
      #   Candidates are: `:pipe`, `:pty`.
      #   See examples for more details.
      # @option opts [Float?] timeout (nil)
      #   See {Pwnlib::Tubes::Tube#initialize}.
      def initialize(argv, **opts)
        opts = {
          in: :pipe,
          out: :pipe
        }.merge(opts)
        super(timeout: opts[:timeout])
        argv = Array(argv)
        slave_i, @i = pipe(opts[:in])
        @o, slave_o = pipe(opts[:out])
        ::Process.spawn(*argv, in: slave_i, out: slave_o)
        slave_i.close
        slave_o.close
      end

      private

      def pipe(type)
        case type
        when :pipe then IO.pipe
        when :pty then PTY.open
        end
      end

      def send_raw(data)
        @i.write(data)
      rescue Errno::EIO
        raise ::Pwnlib::Errors::EndOfTubeError
      end

      def recv_raw(size)
        o, = IO.select([@o], [], [], @timeout)
        return if o.nil?
        # raise ::Pwnlib::Errors::EndOfTubeError if @o.nread.zero? && !@t.alive?
        @o.readpartial(size)
      rescue Errno::EIO
        raise ::Pwnlib::Errors::EndOfTubeError
      end

      def timeout_raw=(timeout)
        @timeout = timeout == :forever ? nil : timeout
      end
    end
  end
end
