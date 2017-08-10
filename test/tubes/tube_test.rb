# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/tubes/tube'

class TubeTest < MiniTest::Test
  include ::Pwnlib::Tubes
  include ::Pwnlib::Context

  def hello_tube
    t = Tube.new
    def t.recv_raw(_)
      'Hello, world'
    end

    def t.timeout_raw=(timeout)
      @timeout = timeout == :forever ? nil : timeout
    end

    class << t
      attr_accessor :buf
    end
    t.buf = ''
    def t.send_raw(data)
      @buf << data
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

    t = Tube.new
    t.unrecv('meow')
    assert_equal('', t.recvuntil('DARKHH'))
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
  end

  def test_recvpred
    t = hello_tube
    r = /H.*w/
    10.times { assert_match(r, t.recvpred { |data| data =~ r }) }
    r = /H.*W/
    assert_match('', t.recvpred(timeout: 0.01) { |data| data =~ r })
    t = Tube.new
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
end
