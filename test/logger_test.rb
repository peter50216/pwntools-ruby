# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/logger'

class LoggerTest < MiniTest::Test
  include ::Pwnlib::Context
  include ::Pwnlib::Logger

  def setup
    @logger = ::Pwnlib::Logger::LoggerType.new
    class << @logger
      def add(*args)
        clear
        super
        @logdev.string
      end

      def indented(*args)
        clear
        super(*args)
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
    x = 2 # rubocop: disable Lint/UselessAssignment
    y = 3 # rubocop: disable Lint/UselessAssignment
    assert_equal(<<-EOS, @logger.dump('x + y', 'x * y'))
[DUMP] x + y = 5, x * y = 6
    EOS
    libc = 0x7fc0bdd13000
    assert_equal(<<-EOS, @logger.dump { libc.to_s(16) })
[DUMP] libc.to_s(16) = "7fc0bdd13000"
    EOS
  end
end
