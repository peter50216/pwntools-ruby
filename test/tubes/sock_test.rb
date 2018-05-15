# encoding: ASCII-8BIT

require 'open3'

require 'test_helper'

require 'pwnlib/tubes/sock'

class SockTest < MiniTest::Test
  include ::Pwnlib::Tubes
  ECHO_FILE = File.expand_path('../data/echo.rb', __dir__)

  def popen_echo(data)
    Open3.popen2("ruby #{ECHO_FILE}") do |_i, o, _t|
      port = o.gets.split.last.to_i
      s = Sock.new('127.0.0.1', port)
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
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.puts(514) }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.puts(514) }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.recv }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.recv }
    end
  end

  def test_close
    popen_echo('DARKHH') do |s, _data, _o|
      s.close
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.puts(514) }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.puts(514) }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.recv }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.recv }
      assert_raises(ArgumentError) { s.close(:hh) }
    end

    popen_echo('DARKHH') do |s, _data, _o|
      3.times { s.close(:read) }
      3.times { s.close(:recv) }
      3.times { s.close(:send) }
      3.times { s.close(:write) }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.puts(514) }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.puts(514) }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.recv }
      assert_raises(::Pwnlib::Errors::EndOfTubeError) { s.recv }
      3.times { s.close }
      assert_raises(ArgumentError) { s.close(:shik) }
    end
  end
end
