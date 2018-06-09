# encoding: ASCII-8BIT

require 'pwnlib/context'
require 'pwnlib/errors'
require 'pwnlib/logger'
require 'pwnlib/timer'
require 'pwnlib/tubes/buffer'
require 'pwnlib/util/hexdump'

module Pwnlib
  # Module that contains all kinds of tubes.
  module Tubes
    # @!macro [new] drop_definition
    #   @param [Boolean] drop
    #     Whether drop the ending.
    #
    # @!macro [new] timeout_definition
    #   @param [Float] timeout
    #     Any positive floating number, indicates timeout in seconds.
    #     Using +context.timeout+ if +timeout+ equals to +nil+.
    #
    # @!macro [new] send_return_definition
    #   @return [Integer]
    #     Returns the number of bytes had been sent.
    #
    # @!macro [new] raise_eof
    #   @raise [Pwnlib::Errors::EndOfTubeError]
    #     If the request is not satisfied when all data is received.
    #
    # @!macro [new] raise_timeout
    #   @raise [Pwnlib::Errors::TimeoutError]
    #     If the request is not satisfied when timeout exceeded.

    # Things common to all tubes (sockets, tty, ...)
    class Tube
      # Receive 4096 bytes each time.
      BUFSIZE = 4096

      # Instantiate a {Pwnlib::Tubes::Tube} object.
      #
      # @!macro timeout_definition
      def initialize(timeout: nil)
        @timer = Timer.new(timeout)
        @buffer = Buffer.new
      end

      # Receives up to +num_bytes+ bytes of data from the tube, and returns as soon as any quantity
      # of data is available.
      #
      # @param [Integer] num_bytes
      #   The maximum number of bytes to receive.
      # @!macro timeout_definition
      #
      # @return [String]
      #   A string contains bytes received from the tube, or +''+ if a timeout occurred while
      #   waiting.
      def recv(num_bytes = nil, timeout: nil)
        return '' if @buffer.empty? && !fillbuffer(timeout: timeout)
        @buffer.get(num_bytes)
      end
      alias read recv

      # Puts the specified data back at the beginning of the receive buffer.
      #
      # @param [String] data
      #   A string to put back.
      #
      # @return [Integer]
      #   The length of the put back data.
      def unrecv(data)
        @buffer.unget(data)
        data.size
      end

      # Receives one byte at a time from the tube, until the predicate evaluates to +true+.
      #
      # @!macro timeout_definition
      #
      # @return [String]
      #   A string contains bytes received from the tube, or +''+ if a timeout occurred while
      #   waiting.
      #
      # @yield
      #   A predicate to evaluate whether the data satisfy the condition.
      #
      # @yieldparam [String] data
      #   A string data to be validated by the predicate.
      #
      # @yieldreturn [Boolean]
      #   Whether the data satisfy the condition.
      #
      # @raise [ArgumentError]
      #   If the block is not given.
      #
      # @!macro raise_eof
      # @!macro raise_timeout
      def recvpred(timeout: nil)
        raise ArgumentError, 'Need a block for recvpred' unless block_given?
        @timer.countdown(timeout) do
          data = ''
          begin
            until yield(data)
              return '' unless @timer.active?

              c = recv(1)

              return '' if c.empty?
              data << c
            end
            data.slice!(0..-1)
          ensure
            unrecv(data)
          end
        end
      end

      # Receives exactly +num_bytes+ bytes.
      # If the request is not satisfied before +timeout+ seconds pass, all data is buffered and an
      # empty string +''+ is returned.
      #
      # @param [Integer] num_bytes
      #   The number of bytes to receive.
      # @!macro timeout_definition
      #
      # @return [String]
      #   A string contains bytes received from the tube, or +''+ if a timeout occurred while
      #   waiting.
      #
      # @!macro raise_eof
      # @!macro raise_timeout
      def recvn(num_bytes, timeout: nil)
        @timer.countdown(timeout) do
          fillbuffer while @timer.active? && @buffer.size < num_bytes
          @buffer.size >= num_bytes ? @buffer.get(num_bytes) : ''
        end
      end
      alias readn recvn

      # Receives data until one of +delims+ is encountered. If the request is not satisfied before
      # +timeout+ seconds pass, all data is buffered and an empty string is returned.
      #
      # @param [Array<String>] delims
      #   String of delimiters characters, or list of delimiter strings.
      # @!macro drop_definition
      # @!macro timeout_definition
      #
      # @return [String]
      #   A string contains bytes, which ends string in +delims+, received from the tube.
      #
      # @!macro raise_eof
      # @!macro raise_timeout
      #
      # @diff We return the string that ends the earliest, rather then starts the earliest,
      #       since the latter can't be done greedly. Still, it would be bad to call this
      #       for case with ambiguity.
      def recvuntil(delims, drop: false, timeout: nil)
        delims = Array(delims)
        max_len = delims.map(&:size).max
        @timer.countdown(timeout) do
          data = Buffer.new
          matching = ''
          begin
            while @timer.active?
              s = recv(1)

              return '' if s.empty?
              matching << s

              sidx = matching.size
              match_len = 0
              delims.each do |d|
                idx = matching.index(d)
                next unless idx
                if idx + d.size <= sidx + match_len
                  sidx = idx
                  match_len = d.size
                end
              end

              if sidx < matching.size
                r = data.get + matching.slice!(0, sidx + match_len)
                r.slice!(-match_len..-1) if drop
                return r
              end

              data << matching.slice!(0...-max_len) if matching.size > max_len
            end
            ''
          ensure
            unrecv(matching)
            unrecv(data)
          end
        end
      end

      # Receives a single line from the tube.
      # A "line" is any sequence of bytes terminated by the byte sequence set in +context.newline+,
      # which defaults to +"\\n"+.
      #
      # @!macro drop_definition
      # @!macro timeout_definition
      #
      # @return [String]
      #   All bytes received over the tube until the first newline is received.
      #   Optionally retains the ending.
      def recvline(drop: false, timeout: nil)
        recvuntil(context.newline, drop: drop, timeout: timeout)
      end

      # Receives the next "line" from the tube; lines are separated by +sep+.
      # The difference with +IO#gets+ is using +context.newline+ as default newline.
      #
      # @param [String, Integer] sep
      #   If +String+ is given, use +sep+ as the separator.
      #   If +Integer+ is given, receive exactly +sep+ bytes.
      # @!macro drop_definition
      # @!macro timeout_definition
      #
      # @return [String]
      #   The next "line".
      #
      # @raise [Pwnlib::Errors::EndOfTubeError]
      #   When the remaining data does not contain +sep+.
      #   When the size of the remaining data is less than +sep+.
      #
      # @example
      #   Sock.new('127.0.0.1', 1337).gets
      #   #=> "This is line one\n"
      #
      #   Sock.new('127.0.0.1', 1337).gets(drop: true)
      #   #=> "This is line one"
      #
      #   Sock.new('127.0.0.1', 1337).gets 'line'
      #   #=> "This is line"
      #
      #   Sock.new('127.0.0.1', 1337).gets ''
      #   #=> "This is line"
      #
      #   Sock.new('127.0.0.1', 1337).gets(4)
      #   #=> "This"
      def gets(sep = context.newline, drop: false, timeout: nil)
        case sep
        when Integer
          recvn(sep, timeout: timeout)
        when String
          recvuntil(sep, drop: drop, timeout: timeout)
        else
          raise ArgumentError, 'only Integer and String are supported'
        end
      end

      # Wrapper around +recvpred+, which will return when a regex matches the string in the buffer.
      #
      # @param [Regexp] regex
      #   A regex to match.
      # @!macro timeout_definition
      #
      # @return [String]
      #   A string contains bytes received from the tube, or +''+ if a timeout occurred while
      #   waiting.
      def recvregex(regex, timeout: nil)
        recvpred(timeout: timeout) { |data| data =~ regex }
      end

      # Sends data.
      #
      # @param [String] data
      #   The +data+ string to be sent.
      #
      # @!macro send_return_definition
      def send(data)
        data = data.to_s
        log.debug(format('Sent %#x bytes:', data.size))
        log.indented(::Pwnlib::Util::HexDump.hexdump(data), level: DEBUG)
        send_raw(data)
        data.size
      end
      alias write send

      # Sends the given object with +context.newline+.
      #
      # @param [Object] obj
      #   The object to be sent.
      #
      # @!macro send_return_definition
      def sendline(obj)
        s = obj.to_s + context.newline
        write(s)
      end

      # Sends the given object(s).
      # The difference with +IO#puts+ is using +context.newline+ as default newline.
      #
      # @param [Array<Object>] objs
      #   The objects to be sent.
      #
      # @!macro send_return_definition
      #
      # @example
      #   s.puts
      #   puts client.recv
      #   #
      #   #=> nil
      #
      # @example
      #   s.puts('shik', "hao\n", 123)
      #   puts client.recv
      #   # shik
      #   # hao
      #   # 123
      #   #=> nil
      #
      # @example
      #   s.puts(["darkhh\n\n", 'wei shi', 360])
      #   puts client.recv
      #   # darkhh
      #   #
      #   # wei shi
      #   # 360
      #   #=> nil
      def puts(*objs)
        return write(context.newline) if objs.empty?
        objs = *objs.flatten
        s = ''
        objs.map(&:to_s).each do |elem|
          s << elem
          s << context.newline unless elem.end_with?(context.newline)
        end
        write(s)
      end

      # Does simultaneous reading and writing to the tube. In principle this just connects the tube
      # to standard in and standard out.
      def interact
        log.info('Switching to interactive mode')
        $stdout.write(@buffer.get)
        until io_out.closed?
          rs, = IO.select([$stdin, io_out])
          if rs.include?($stdin)
            s = $stdin.readpartial(BUFSIZE)
            write(s)
          end
          if rs.include?(io_out)
            s = recv
            $stdout.write(s)
          end
        end
      rescue ::Pwnlib::Errors::EndOfTubeError
        log.info('Got EOF in interactive mode')
      end

      private

      # Normalize direction.
      #
      # @param [Symbol] direction
      #
      # @return [Array<Symbol>]
      #   If +direction+ equals to
      #   * +:both+, returns +[:read, :write]+
      #   * +:read+ or +:recv+, returns [:read]
      #   * +:write+ or +:send+, returns [:write]
      #   Otherwise, raise +ArgumentError+.
      def normalize_direction(direction)
        case direction
        when :both then %i[read write]
        when :read, :recv then [:read]
        when :write, :send then [:write]
        else
          raise ArgumentError, 'Only allow :both, :recv, :read, :send and :write passed'
        end
      end

      def fillbuffer(timeout: nil)
        data = @timer.countdown(timeout) do
          self.timeout_raw = (@timer.timeout == :forever ? nil : @timer.timeout)
          recv_raw(BUFSIZE)
        end
        if data
          @buffer << data
          log.debug(format('Received %#x bytes:', data.size))
          log.indented(::Pwnlib::Util::HexDump.hexdump(data), level: DEBUG)
        end
        data
      end

      # The IO object of output, will be used for IO.select([io_out]) in interactive mode.
      #
      # @return [IO]
      def io_out
        raise NotImplementedError, 'Not implemented'
      end

      # @param [String] _data
      #
      # @return [void]
      def send_raw(_data)
        raise NotImplementedError, 'Not implemented'
      end

      # @param [Integer] _size
      #
      # @return [String]
      def recv_raw(_size)
        raise NotImplementedError, 'Not implemented'
      end

      # @param [Float?] _timeout
      #
      # @return [void]
      def timeout_raw=(_timeout)
        raise NotImplementedError, 'Not implemented'
      end

      include ::Pwnlib::Context
      include ::Pwnlib::Logger
    end
  end
end
