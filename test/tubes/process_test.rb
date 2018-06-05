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

  def test_eof
    ls = ::Pwnlib::Tubes::Process.new(['ls', '-la'])
    assert_match(/total/, ls.gets)
    assert_raises(::Pwnlib::Errors::EndOfTubeError) { ls.write('anything') }
    assert_raises(::Pwnlib::Errors::EndOfTubeError) { loop { ls.gets } }
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
