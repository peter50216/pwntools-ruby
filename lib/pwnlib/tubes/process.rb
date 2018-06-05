# encoding: ASCII-8BIT

require 'pty'

require 'pwnlib/errors'
require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # Launch a process.
    class Process < Tube
      # Default options for {#initialize}.
      DEFAULT_OPTIONS = {
        in: :pipe,
        out: :pipe,
        raw: true
      }.freeze

      # Instantiate a {Pwnlib::Tubes::Process} object.
      #
      # @param [Array<String>, String] argv
      #   List of arguments to pass to the spawned process.
      #
      # @option opts [Symbol] in (:pipe)
      #   What kind of io should be used for `stdin`.
      #   Candidates are: `:pipe`, `:pty`.
      # @option opts [Symbol] out (:pipe)
      #   What kind of io should be used for `stdout`.
      #   Candidates are: `:pipe`, `:pty`.
      #   See examples for more details.
      # @option opts [Boolean] raw (true)
      #   Set the created PTY to raw mode. i.e. disable control characters.
      #   If no pty is created, this has no effect.
      # @option opts [Float?] timeout (nil)
      #   See {Pwnlib::Tubes::Tube#initialize}.
      def initialize(argv, **opts)
        opts = DEFAULT_OPTIONS.merge(opts)
        super(timeout: opts[:timeout])
        argv = Array(argv)
        slave_i, @i = pipe(opts[:in], opts[:raw])
        @o, slave_o = pipe(opts[:out], opts[:raw])
        @pid = ::Process.spawn(*argv, in: slave_i, out: slave_o)
        slave_i.close
        slave_o.close
      end

      # Close the IO.
      #
      # @param [:both, :recv, :read, :send, :write] direction
      #   Disallow further read/write of the process.
      def shutdown(direction = :both)
        case direction
        when :both then close_io(%i[read write])
        when :recv, :read then close_io(:read)
        when :send, :write then close_io(:write)
        else
          raise ArgumentError, 'Only allow :both, :recv, :read, :send and :write passed'
        end
      end

      # Kill the process.
      #
      # @return [void]
      def kill
        shutdown
        ::Process.kill('KILL', @pid)
        ::Process.wait(@pid)
      end
      alias close kill

      private

      def close_io(*dir)
        @o.close if dir.include?(:read)
        @i.close if dir.include?(:write)
      end

      # @return [(IO, IO)]
      #   IO pair.
      def pipe(type, raw)
        case type
        when :pipe then IO.pipe
        when :pty then PTY.open.tap { |mst, _slv| mst.raw! if raw }
        end
      end

      def send_raw(data)
        @i.write(data)
      rescue Errno::EIO, Errno::EPIPE, IOError
        raise ::Pwnlib::Errors::EndOfTubeError
      end

      def recv_raw(size)
        o, = IO.select([@o], [], [], @timeout)
        return if o.nil?
        @o.readpartial(size)
      rescue Errno::EIO, Errno::EPIPE, IOError
        raise ::Pwnlib::Errors::EndOfTubeError
      end

      def timeout_raw=(timeout)
        @timeout = timeout
      end
    end
  end
end
