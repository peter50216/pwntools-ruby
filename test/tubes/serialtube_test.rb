# encoding: ASCII-8BIT

require 'open3'

require 'test_helper'

require 'pwnlib/tubes/serialtube'

class SerialTest < MiniTest::Test
  include ::Pwnlib::Tubes

  def open_pair
    Open3.popen3('socat -d -d pty,raw,echo=0 pty,raw,echo=0') do |_i, _o, stderr, thread|
      devs = []
      2.times do
        devs << stderr.readline.chomp.split.last
        if devs.last !~ %r{^/dev/pts/[0-9]+$}
          raise IOError, 'Could not create serial crosslink'
        end
      end

      serial = SerialTube.new devs[1], convert_newlines: false
      File.open devs[0], 'r+' do |file|
        file.set_encoding 'default'.encoding
        yield file, serial
      end

      Process.kill('SIGTERM', thread.pid)
    end
  end

  def random_string(length)
    Random.rand(36**length).to_s(36).encode('default'.encoding)
  end

  def test_recv
    open_pair do |file, serial|
      # recv, recvline
      rs = random_string 24
      file.puts rs
      result = serial.recv 12
      assert_equal(rs[0...12], result)
      result = serial.recvline.chomp
      assert_equal(rs[12..-1], result)

      assert_empty serial.recv(1, timeout: 1)

      # recvpred
      rs = random_string 12
      file.print rs
      result = serial.recvpred do |data|
        data[-6..-1] == rs[-6..-1]
      end
      assert_equal rs, result

      assert_empty serial.recv(1, timeout: 1)

      # recvn
      rs = random_string 6
      file.print rs
      result = serial.recvn 12, timeout: 1
      assert_empty result
      file.print rs
      result = serial.recvn 12
      assert_equal rs * 2, result

      assert_empty serial.recv(1, timeout: 1)

      # recvuntil
      rs = random_string 12
      file.print rs + '|'
      result = serial.recvuntil('|').chomp('|')
      assert_equal rs, result

      assert_empty serial.recv(1, timeout: 1)

      # gets
      rs = random_string 24
      file.puts rs
      result = serial.gets 12
      assert_equal rs[0...12], result
      result = serial.gets.chomp
      assert_equal rs[12..-1], result

      assert_empty serial.recv(1, timeout: 1)
    end
  end

  def test_send
    open_pair do |file, serial|
      # send, sendline
      rs = random_string 24
      serial.send rs[0...12]
      serial.sendline rs[12...24]
      result = file.readline.chomp
      assert_equal rs, result

      # puts
      r1 = random_string 4
      r2 = random_string 4
      r3 = random_string 4
      serial.puts r1, r2, r3
      result = ''
      3.times do
        result += file.readline.chomp
      end
      assert_equal r1 + r2 + r3, result
    end
  end

  def test_close
    open_pair do |_file, serial|
      serial.close
      assert_raises(EOFError) { serial.puts(514) }
      assert_raises(EOFError) { serial.puts(514) }
      assert_raises(EOFError) { serial.recv }
      assert_raises(EOFError) { serial.recv }
      assert_raises(ArgumentError) { serial.close(:hh) }
    end
  end
end
