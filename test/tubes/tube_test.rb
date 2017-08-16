# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/tubes/tube'

class TubeTest < MiniTest::Test
  include ::Pwnlib::Tubes
  include ::Pwnlib::Context

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
end
