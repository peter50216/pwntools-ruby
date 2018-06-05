# encoding: ASCII-8BIT

require 'io/console'
require 'pty'

require 'pwnlib/errors'
require 'pwnlib/tubes/tube'

module Pwnlib
  module Tubes
    # Launch a process.
    class Process < Tube
      # Default options for {#initialize}.
      DEFAULT_OPTIONS = {
        env: ENV,
        in: :pipe,
        out: :pipe,
        raw: true,
        aslr: true
      }.freeze

      # Instantiate a {Pwnlib::Tubes::Process} object.
      #
      # @param [Array<String>, String] argv
      #   List of arguments to pass to the spawned process.
      #
      # @option opts [Hash{String => String}] env (ENV)
      #   Environment variables. By default, inherits from Ruby's environment.
      # @option opts [Symbol] in (:pipe)
      #   What kind of io should be used for +stdin+.
      #   Candidates are: +:pipe+, +:pty+.
      # @option opts [Symbol] out (:pipe)
      #   What kind of io should be used for +stdout+.
      #   Candidates are: +:pipe+, +:pty+.
      #   See examples for more details.
      # @option opts [Boolean] raw (true)
      #   Set the created PTY to raw mode. i.e. disable control characters.
      #   If no pty is created, this has no effect.
      # @option opts [Boolean] aslr (true)
      #   If +false+ is given, the ASLR of the target process will be disabled via +setarch -R+.
      # @option opts [Float?] timeout (nil)
      #   See {Pwnlib::Tubes::Tube#initialize}.
      #
      # @example
      #   io = Tubes::Process.new('ls')
      #   io.gets
      #   #=> "Gemfile\n"
      #
      #   io = Tubes::Process.new('ls', out: :pty)
      #   io.gets
      #   #=> "Gemfile       LICENSE-pwntools-python.txt  STYLE.md\t git-hooks  pwntools-1.0.1.gem  test\n"
      # @example
      #    io = Tubes::Process.new('cat /proc/self/maps')
      #    io.gets
      #    #=> "55f8b8a10000-55f8b8a18000 r-xp 00000000 fd:00 9044035                    /bin/cat\n"
      #    io.close
      #
      #    io = Tubes::Process.new('cat /proc/self/maps', aslr: false)
      #    io.gets
      #    #=> "555555554000-55555555c000 r-xp 00000000 fd:00 9044035                    /bin/cat\n"
      #    io.close
      # @example
      #   io = Tubes::Process.new('env', env: { 'FOO' => 'BAR' })
      #   io.gets
      #   #=> "FOO=BAR\n"
      def initialize(argv, **opts)
        opts = DEFAULT_OPTIONS.merge(opts)
        super(timeout: opts[:timeout])
        argv = normalize_argv(argv, opts)
        slave_i, @i = pipe(opts[:in], opts[:raw])
        @o, slave_o = pipe(opts[:out], opts[:raw])
        @pid = ::Process.spawn(opts[:env], *argv, in: slave_i, out: slave_o, unsetenv_others: true)
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

      def normalize_argv(argv, opts)
        # XXX(david942j): Set personality on child process will be better than using setarch
        pre_cmd = opts[:aslr] ? '' : "setarch #{`uname -m`.strip} -R "
        argv = if argv.is_a?(String)
                 pre_cmd + argv
               else
                 pre_cmd.split + argv
               end
        Array(argv)
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
