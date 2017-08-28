# encoding: UTF-8

# This test use UTF-8 encoding for strings since the output for hexdump contains lots of UTF-8 characters.

require 'rainbow'

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/logger'
require 'pwnlib/util/hexdump'

class LoggerTest < MiniTest::Test
  include ::Pwnlib::Context
  include ::Pwnlib::Logger
  include ::Pwnlib::Util::HexDump

  def setup
    # Default to disable coloring for easier testing.
    Rainbow.enabled = false

    @logger = ::Pwnlib::Logger::LoggerType.new
    class << @logger
      def initialize
        super
        clear
      end

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
    assert_silent { logger.indented(hexdump('darkhh'), level: DEBUG) }

    assert_empty(@logger.indented(hexdump('A'), level: DEBUG))

    assert_equal(<<-EOS, @logger.indented(hexdump('A'), level: INFO))
    00000000  41                                                  │A│
    00000001
    EOS

    assert_equal(<<-EOS, @logger.indented(hexdump('><>><>><>><>><>><>>'), level: WARN))
    00000000  3e 3c 3e 3e  3c 3e 3e 3c  3e 3e 3c 3e  3e 3c 3e 3e  │><>>│<>><│>><>│><>>│
    00000010  3c 3e 3e                                            │<>>│
    00000013
    EOS

    assert_equal(<<-'EOS', @logger.indented(hexdump('ABCD' * 5), level: ERROR))
    00000000  41 42 43 44  41 42 43 44  41 42 43 44  41 42 43 44  │ABCD│ABCD│ABCD│ABCD│
    00000010  41 42 43 44                                         │ABCD│
    00000014
    EOS

    assert_equal(<<-'EOS', @logger.indented(hexdump((0..255).map(&:chr).join), level: FATAL))
    00000000  00 01 02 03  04 05 06 07  08 09 0a 0b  0c 0d 0e 0f  │····│····│····│····│
    00000010  10 11 12 13  14 15 16 17  18 19 1a 1b  1c 1d 1e 1f  │····│····│····│····│
    00000020  20 21 22 23  24 25 26 27  28 29 2a 2b  2c 2d 2e 2f  │ !"#│$%&'│()*+│,-./│
    00000030  30 31 32 33  34 35 36 37  38 39 3a 3b  3c 3d 3e 3f  │0123│4567│89:;│<=>?│
    00000040  40 41 42 43  44 45 46 47  48 49 4a 4b  4c 4d 4e 4f  │@ABC│DEFG│HIJK│LMNO│
    00000050  50 51 52 53  54 55 56 57  58 59 5a 5b  5c 5d 5e 5f  │PQRS│TUVW│XYZ[│\]^_│
    00000060  60 61 62 63  64 65 66 67  68 69 6a 6b  6c 6d 6e 6f  │`abc│defg│hijk│lmno│
    00000070  70 71 72 73  74 75 76 77  78 79 7a 7b  7c 7d 7e 7f  │pqrs│tuvw│xyz{│|}~·│
    00000080  80 81 82 83  84 85 86 87  88 89 8a 8b  8c 8d 8e 8f  │····│····│····│····│
    00000090  90 91 92 93  94 95 96 97  98 99 9a 9b  9c 9d 9e 9f  │····│····│····│····│
    000000a0  a0 a1 a2 a3  a4 a5 a6 a7  a8 a9 aa ab  ac ad ae af  │····│····│····│····│
    000000b0  b0 b1 b2 b3  b4 b5 b6 b7  b8 b9 ba bb  bc bd be bf  │····│····│····│····│
    000000c0  c0 c1 c2 c3  c4 c5 c6 c7  c8 c9 ca cb  cc cd ce cf  │····│····│····│····│
    000000d0  d0 d1 d2 d3  d4 d5 d6 d7  d8 d9 da db  dc dd de df  │····│····│····│····│
    000000e0  e0 e1 e2 e3  e4 e5 e6 e7  e8 e9 ea eb  ec ed ee ef  │····│····│····│····│
    000000f0  f0 f1 f2 f3  f4 f5 f6 f7  f8 f9 fa fb  fc fd fe ff  │····│····│····│····│
    00000100
    EOS

    context.local(log_level: :error) do
      assert_empty(@logger.indented(hexdump('A'), level: DEBUG))
      assert_empty(@logger.indented(hexdump('A'), level: INFO))
      assert_empty(@logger.indented(hexdump('A'), level: WARN))
    end
  end
end
