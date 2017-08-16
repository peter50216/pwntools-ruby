# encoding: ASCII-8BIT

require 'open3'

require 'test_helper'

require 'pwnlib/tubes/sock'

class SockTest < MiniTest::Test
  include ::Pwnlib::Tubes
  ECHO_FILE = File.expand_path('../data/echo.rb', __dir__)
  BIND_PORT = 31_337

  def popen_echo(data)
    Open3.popen2("bundle exec ruby #{ECHO_FILE} #{BIND_PORT}") do |_i, o, _t|
      o.gets
      s = Sock.new('localhost', BIND_PORT)
      yield s, data, o
    end
  end

  def test_io
    popen_echo('DARKHH') do |s, data, _o|
      s.io.puts(data)
      rs, = IO.select([s.io])
      refute_nil(rs)
      assert_equal(data, s.io.readpartial(data.size))
    end
  end

  def test_sock
    popen_echo('DARKHH') do |s, data, o|
      s.puts(data)
      assert_equal(data + "\n", s.gets)
      o.gets
      s.puts(514)
      sleep(0.1) # Wait for connection reset
      assert_raises(EOFError) { s.puts(514) }
      assert_raises(EOFError) { s.puts(514) }
      assert_raises(EOFError) { s.recv }
      assert_raises(EOFError) { s.recv }
    end
  end

  def test_close
    popen_echo('DARKHH') do |s, _data, _o|
      s.close
      assert_raises(EOFError) { s.puts(514) }
      assert_raises(EOFError) { s.puts(514) }
      assert_raises(EOFError) { s.recv }
      assert_raises(EOFError) { s.recv }
    end
  end
end
