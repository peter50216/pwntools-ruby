# encoding: ASCII-8BIT

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
      #   Set the created PTY to raw mode. i.e. disable echo and control characters.
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
      #   #=> "Gemfile       LICENSE\t\t\t   README.md  STYLE.md\t    git-hooks  pwntools.gemspec  test\n"
      # @example
      #   io = Tubes::Process.new('cat /proc/self/maps')
      #   io.gets
      #   #=> "55f8b8a10000-55f8b8a18000 r-xp 00000000 fd:00 9044035                    /bin/cat\n"
      #   io.close
      #
      #   io = Tubes::Process.new('cat /proc/self/maps', aslr: false)
      #   io.gets
      #   #=> "555555554000-55555555c000 r-xp 00000000 fd:00 9044035                    /bin/cat\n"
      #   io.close
      # @example
      #   io = Tubes::Process.new('env', env: { 'FOO' => 'BAR' })
      #   io.gets
      #   #=> "FOO=BAR\n"
      def initialize(argv, **opts)
        opts = DEFAULT_OPTIONS.merge(opts)
        super(timeout: opts[:timeout])
        argv = normalize_argv(argv, opts)
        slave_i, slave_o = create_pipe(opts)
        @pid = ::Process.spawn(opts[:env], *argv, in: slave_i, out: slave_o, unsetenv_others: true)
        slave_i.close
        slave_o.close unless slave_i == slave_o
      end

      # Close the IO.
      #
      # @param [:both, :recv, :read, :send, :write] direction
      #   Disallow further read/write of the process.
      #
      # @return [void]
      def shutdown(direction = :both)
        close_io(normalize_direction(direction))
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

      def io_out
        @o
      end

      def close_io(dirs)
        @o.close if dirs.include?(:read)
        @i.close if dirs.include?(:write)
      end

      def normalize_argv(argv, opts)
        # XXX(david942j): Set personality on child process will be better than using setarch
        pre_cmd = opts[:aslr] ? '' : "setarch #{`uname -m`.strip} -R "
        pre_cmd = pre_cmd.split if argv.is_a?(Array)
        Array(pre_cmd + argv)
      end

      def create_pipe(opts)
        if [opts[:in], opts[:out]].include?(:pty)
          # Require only when we need it.
          # This prevents broken on Windows, which has no pty support.
          require 'io/console'
          require 'pty'
          mpty, spty = PTY.open
          mpty.raw! if opts[:raw]
        end
        @o, slave_o = pipe(opts[:out], mpty, spty)
        slave_i, @i = pipe(opts[:in], spty, mpty)
        [slave_i, slave_o]
      end

      # @return [(IO, IO)]
      #   IO pair.
      def pipe(type, mst, slv)
        case type
        when :pipe then IO.pipe
        when :pty then [mst, slv]
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
