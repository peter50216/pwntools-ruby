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
end
