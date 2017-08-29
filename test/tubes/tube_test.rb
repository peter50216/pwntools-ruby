# encoding: UTF-8

# This test use UTF-8 encoding for strings since the output for hexdump contains lots of UTF-8 characters.

require 'rainbow'

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/logger'
require 'pwnlib/tubes/tube'

class TubeTest < MiniTest::Test
  include ::Pwnlib::Context
  include ::Pwnlib::Tubes

  def setup
    # Default to disable coloring for easier testing.
    Rainbow.enabled = false

    @old_log = ::Pwnlib::Logger.log.dup
    @log = ::Pwnlib::Logger::LoggerType.new

    class << @log
      def clear
        @logdev = StringIO.new
      end

      def string
        @logdev.string
      end
    end

    ::Pwnlib::Logger.instance_variable_set(:@log, @log)
  end

  def hello_tube
    t = Tube.new

    class << t
      def buf
        @buf ||= ''
      end

      private

      def recv_raw(_n)
        'Hello, world'
      end

      def timeout_raw=(timeout)
        @timeout = timeout == :forever ? nil : timeout
      end

      def send_raw(data)
        buf << data
      end
    end

    t
  end

  def hello_once_tube
    t = Tube.new

    t.unrecv('Hello, world')
    class << t
      def recv_raw
        raise EOFError
      end

      def timeout_raw=(timeout)
        @timeout = timeout == :forever ? nil : timeout
      end
    end

    t
  end

  def eof_tube
    t = Tube.new
    class << t
      def recv_raw(_size)
        raise EOFError
      end

      def timeout_raw=(_timeout); end
    end

    t
  end

  def test_recv
    t = hello_tube
    assert_equal('Hello, world', t.recv)
    assert_equal('Hello, world', t.recv)
    t.unrecv('Woohoo')
    assert_equal('Woohoo', t.recv)
    assert_equal('Hello, world', t.recv)
    assert_equal('H', t.recvn(1))
    assert_equal('ello, w', t.recvn(7))
    assert_equal('orldH', t.recvn(5))
    assert_equal('ello, world', t.recv)

    context.local(log_level: 'debug') do
      @log.clear
      t = hello_tube
      assert_equal('Hello, world', t.recv)
      assert_equal(<<-EOS, @log.string)
[DEBUG] Received 0xc bytes:
    00000000  48 65 6c 6c  6f 2c 20 77  6f 72 6c 64               │Hell│o, w│orld│
    0000000c
      EOS
    end
  end

  def test_recvuntil
    t = hello_tube
    assert_equal('Hello, ', t.recvuntil(' '))
    assert_equal('worldHello, ', t.recvuntil(' '))
    t.unrecv('Hello, world!')
    assert_equal('Hello,', t.recvuntil(' wor', drop: true))
    assert_equal('', t.recvuntil('DARKHH', drop: true, timeout: 0.1))

    t = eof_tube
    t.unrecv('meow')
    assert_equal('', t.recvuntil('DARKHH'))
    assert_equal('meow', t.recv)
  end

  def test_recvline
    t = Tube.new
    t.unrecv("Foo\nBar\r\nBaz\n")
    assert_equal("Foo\n", t.recvline)
    assert_equal("Bar\r\n", t.recvline)
    assert_equal('Baz', t.recvline(drop: true))
    context.local(newline: "\r\n") do
      t = Tube.new
      t.unrecv("Foo\nBar\r\nBaz\n")
      assert_equal("Foo\nBar", t.recvline(drop: true))
    end

    t = hello_once_tube
    assert_equal('', t.recvline)
    assert_equal('Hello, world', t.recv)
  end

  def test_recvpred
    t = hello_tube
    r = /H.*w/
    10.times { assert_match(r, t.recvpred { |data| data =~ r }) }
    r = /H.*W/
    assert_match('', t.recvpred(timeout: 0.01) { |data| data =~ r })
    t = eof_tube
    t.unrecv('darkhh')
    assert_match('', t.recvpred { |data| data =~ r })
  end

  def test_recvregex
    t = hello_tube
    r = /[aeiou]/
    5.times { assert_match(r, t.recvregex(r)) }
    r = /[wl][aeiou]/
    5.times { assert_match(r, t.recvregex(r)) }
  end

  def test_send
    t = hello_tube
    t.write('DARKHH')
    assert_equal('DARKHH', t.buf)
    t.write(' QQ')
    assert_equal('DARKHH QQ', t.buf)
    t.write(333)
    assert_equal('DARKHH QQ333', t.buf)

    context.local(log_level: 'debug') do
      @log.clear
      data = (0..40).map(&:chr).join
      t = hello_tube
      t.write(data)
      assert_equal(data, t.buf)
      assert_equal(<<-EOS, @log.string)
[DEBUG] Sent 0x29 bytes:
    00000000  00 01 02 03  04 05 06 07  08 09 0a 0b  0c 0d 0e 0f  │····│····│····│····│
    00000010  10 11 12 13  14 15 16 17  18 19 1a 1b  1c 1d 1e 1f  │····│····│····│····│
    00000020  20 21 22 23  24 25 26 27  28                        │ !"#│$%&'│(│
    00000029
    EOS
    end
  end

  def test_sendline
    t = hello_tube
    t.write('DARKHH')
    assert_equal('DARKHH', t.buf)
    t.puts(' QQ')
    assert_equal("DARKHH QQ\n", t.buf)
  end

  FLAG_FILE = File.expand_path('../data/flag', __dir__)
  def test_interact_send
    save_stdin = $stdin.dup
    $stdin = File.new(FLAG_FILE, File::RDONLY)
    begin
      t = Tube.new
      def t.io
        @fakeio ||= Tempfile.new('pwntools_ruby_test')
      end
      t.interact
    rescue EOFError
      t.io.rewind
      assert_equal(IO.binread(FLAG_FILE), t.io.read)
    end
    $stdin.close
    t.io.close
    $stdin = save_stdin
  end

  def test_interact_recv
    save_stdin = $stdin.dup
    save_stdout = $stdout.dup
    $stdin = UDPSocket.new
    $stdout = Tempfile.new('pwntools_ruby_test')
    begin
      t = Tube.new
      def t.io
        @fakeio ||= File.new(FLAG_FILE, File::RDONLY)
      end
      t.interact
    rescue EOFError
      $stdout.rewind
      assert_equal(IO.binread(FLAG_FILE), $stdout.read)
    end
    $stdout.close
    t.io.close
    $stdin = save_stdin
    $stdout = save_stdout
  end

  def teardown
    ::Pwnlib::Logger.instance_variable_set(:@log, @old_log)
  end
end
