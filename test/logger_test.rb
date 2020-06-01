# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'open3'
require 'tempfile'

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/logger'

class LoggerTest < MiniTest::Test
  include ::Pwnlib::Context
  include ::Pwnlib::Logger

  def setup
    @logger = ::Pwnlib::Logger::LoggerType.new
    class << @logger
      def add(*)
        clear
        super
        @logdev.string
      end

      def indented(*, **)
        clear
        super
        @logdev.string
      end

      def clear
        @logdev = StringIO.new
      end
    end
  end

  def test_log
    str = 'darkhh i4 so s4d'
    context.local(log_level: DEBUG) do
      %w(DEBUG INFO WARN ERROR FATAL).each do |type|
        assert_equal("[#{type}] #{str}\n", @logger.public_send(type.downcase, str))
        assert_equal("[#{type}] #{str}\n", @logger.public_send(type.downcase) { str })
      end
    end

    assert_empty(@logger.debug(str))
    assert_empty(@logger.debug { str })
    %w(INFO WARN ERROR FATAL).each do |type|
      assert_equal("[#{type}] #{str}\n", @logger.public_send(type.downcase, str))
      assert_equal("[#{type}] #{str}\n", @logger.public_send(type.downcase) { str })
    end
  end

  def test_indented
    assert_silent { log.indented('darkhh', level: DEBUG) }
    assert_empty(@logger.indented('A', level: DEBUG))

    data = ['meow', 'meow meow', 'meowmeowmeow'].join("\n")
    assert_equal(<<-EOS, @logger.indented(data, level: INFO))
    meow
    meow meow
    meowmeowmeow
    EOS
  end

  def test_dump
    x = 2
    y = 3
    assert_equal(<<-EOS, @logger.dump(x + y, x * y))
[DUMP] (x + y) = 5, (x * y) = 6
    EOS

    libc = 0x7fc0bdd13000
    # check if source code parsing works good
    msg = @logger.dump(
      libc # comment is ok
      .to_s(16),
      libc - libc
    )
    assert_equal(<<-EOS, msg)
[DUMP] libc.to_s(16) = "7fc0bdd13000", (libc - libc) = 0
    EOS

    libc = 0x7fc0bdd13000
    assert_equal(<<-EOS, @logger.dump { libc.to_s(16) })
[DUMP] libc.to_s(16) = "7fc0bdd13000"
    EOS

    res = @logger.dump do
      libc = 12_345_678
      libc <<= 12
      # comments will be ignored
      libc.to_s # dummy line
      libc.to_s(16)
    end
    assert_equal(<<-EOS, res)
[DUMP] libc = 12345678
       libc = (libc << 12)
       libc.to_s
       libc.to_s(16) = "bc614e000"
    EOS

    lib_path = File.expand_path(File.join(__dir__, '..', 'lib'))
    f = Tempfile.new(['dump', '.rb'])
    begin
      f.write <<~EOS
        $LOAD_PATH.unshift #{lib_path.inspect}
        require 'pwn'
        FileUtils.remove(__FILE__)
        log.dump 1337
      EOS
      f.close
      _, stderr, status = Open3.capture3('ruby', f.path, binmode: true)
      assert(status.success?, stderr)
    ensure
      f.close
      f.unlink
    end
  end
end
