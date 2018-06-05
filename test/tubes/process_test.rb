# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/errors'
require 'pwnlib/tubes/process'

class ProcessTest < MiniTest::Test
  include ::Pwnlib::Tubes

  def test_io
    cat = ::Pwnlib::Tubes::Process.new('cat')
    cat.puts('HAHA')
    assert_equal("HAHA\n", cat.gets)
    assert_raises(::Pwnlib::Errors::TimeoutError) { cat.gets(timeout: 0.1) }
    cat.puts('HAHA2')
    assert_equal("HAHA2\n", cat.gets)
  end

  def test_env
    data = ::Pwnlib::Tubes::Process.new('env').read
    assert_match('PATH=', data)
    data = ::Pwnlib::Tubes::Process.new('env', env: { 'FOO' => 'BAR' }).read
    assert_equal("FOO=BAR\n", data)
  end

  def test_aslr
    map1 = ::Pwnlib::Tubes::Process.new('cat /proc/self/maps', aslr: false).read
    map2 = ::Pwnlib::Tubes::Process.new(['cat', '/proc/self/maps'], aslr: false).read
    assert_match('/bin/cat', map1) # make sure it read something
    assert_equal(map1, map2)
  end

  def test_eof
    ls = ::Pwnlib::Tubes::Process.new(['ls', '-la'])
    assert_match(/total/, ls.gets)
    assert_raises(::Pwnlib::Errors::EndOfTubeError) { ls.write('anything') }
    assert_raises(::Pwnlib::Errors::EndOfTubeError) { loop { ls.gets } }
  end

  def test_shutdown
    cat = ::Pwnlib::Tubes::Process.new('cat')
    assert_raises(::Pwnlib::Errors::TimeoutError) { cat.recvn(1, timeout: 0.1) }
    cat.shutdown(:write) # This should cause `cat` dead
    assert_raises(::Pwnlib::Errors::EndOfTubeError) { cat.recvn(1, timeout: 0.1) }
    cat.shutdown

    cat = ::Pwnlib::Tubes::Process.new('cat')
    cat.shutdown(:recv)
    assert_raises(::Pwnlib::Errors::EndOfTubeError) { cat.recvn(1) }
    cat.shutdown
    assert_raises(ArgumentError) { cat.shutdown(:zz) }
  end

  def test_kill
    cat = ::Pwnlib::Tubes::Process.new('cat')
    cat.kill
    assert_raises(::Pwnlib::Errors::EndOfTubeError) { cat.recvn(1) }
  end

  def test_tty
    tty_test = proc do |*args, raw: true|
      in_, out = args.map { |v| v ? :pty : :pipe }
      process = ::Pwnlib::Tubes::Process.new('ruby -e "p [STDIN.tty?, STDOUT.tty?]"',
                                             in: in_, out: out, raw: raw)
      process.gets
    end
    assert_equal("[false, false]\n", tty_test.call(false, false))
    assert_equal("[true, false]\n", tty_test.call(true, false))
    assert_equal("[false, true]\n", tty_test.call(false, true))
    assert_equal("[false, true]\r\n", tty_test.call(false, true, raw: false))
  end
end
