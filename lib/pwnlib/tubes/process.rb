# encoding: ASCII-8BIT

require 'open3'
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

      private

      def pipe(type, raw)
        case type
        when :pipe then IO.pipe
        when :pty then PTY.open.tap { |mst, _slv| mst.raw! if raw }
        end
      end

      def send_raw(data)
        @i.write(data)
      rescue Errno::EIO, Errno::EPIPE
        raise ::Pwnlib::Errors::EndOfTubeError
      end

      def recv_raw(size)
        o, = IO.select([@o], [], [], @timeout)
        return if o.nil?
        @o.readpartial(size)
      rescue Errno::EIO, Errno::EPIPE, EOFError
        raise ::Pwnlib::Errors::EndOfTubeError
      end

      def timeout_raw=(timeout)
        @timeout = timeout == :forever ? nil : timeout
      end
    end
  end
end
