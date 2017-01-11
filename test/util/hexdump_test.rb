require 'rainbow'

require 'test_helper'
require 'pwnlib/util/hexdump'

class HexDumpTest < MiniTest::Test
  include ::Pwnlib::Util::HexDump::ClassMethod

  def setup
    # Default to disable coloring for easier testing.
    Rainbow.enabled = false
  end

  def assert_lines_equal(s1, s2)
    s1l = s1.chomp.lines
    s2l = s2.chomp.lines
    assert_equal(s1l, s2l)
  end

  def test_hexdump_basic
    assert_lines_equal(<<-'EOS', hexdump('A'))
00000000  41                                                  │A│
00000001
    EOS
    assert_lines_equal(<<-'EOS', hexdump('ABCD'))
00000000  41 42 43 44                                         │ABCD│
00000004
    EOS
    assert_lines_equal(<<-'EOS', hexdump('<3 Ruby :)'))
00000000  3c 33 20 52  75 62 79 20  3a 29                     │<3 R│uby │:)│
0000000a
    EOS
    assert_lines_equal(<<-'EOS', hexdump('><>><>><>><>><>><>>'))
00000000  3e 3c 3e 3e  3c 3e 3e 3c  3e 3e 3c 3e  3e 3c 3e 3e  │><>>│<>><│>><>│><>>│
00000010  3c 3e 3e                                            │<>>│
00000013
    EOS
    assert_lines_equal(<<-'EOS', hexdump('ABCD' * 5))
00000000  41 42 43 44  41 42 43 44  41 42 43 44  41 42 43 44  │ABCD│ABCD│ABCD│ABCD│
00000010  41 42 43 44                                         │ABCD│
00000014
    EOS
    assert_lines_equal(<<-'EOS', hexdump((0..255).map(&:chr).join))
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
  end

  def test_hexdump_width
    assert_lines_equal(<<-'EOS', hexdump('vert~', width: 1))
00000000  76  │v│
00000001  65  │e│
00000002  72  │r│
00000003  74  │t│
00000004  7e  │~│
00000005
    EOS
    assert_lines_equal(<<-'EOS', hexdump('~!@$%^&*()_+{}:"<>?', width: 13))
00000000  7e 21 40 24  25 5e 26 2a  28 29 5f 2b  7b  │~!@$│%^&*│()_+│{│
0000000d  7d 3a 22 3c  3e 3f                         │}:"<│>?│
00000013
    EOS
    assert_lines_equal(<<-'EOS', hexdump('xoxoxoxo', width: 6))
00000000  78 6f 78 6f  78 6f  │xoxo│xo│
00000006  78 6f               │xo│
00000008
    EOS
  end

  def test_hexdump_skip
    assert_lines_equal(<<-'EOS', hexdump('A' * 49))
00000000  41 41 41 41  41 41 41 41  41 41 41 41  41 41 41 41  │AAAA│AAAA│AAAA│AAAA│
*
00000030  41                                                  │A│
00000031
    EOS
    assert_lines_equal(<<-'EOS', hexdump('A' * 49, skip: false))
00000000  41 41 41 41  41 41 41 41  41 41 41 41  41 41 41 41  │AAAA│AAAA│AAAA│AAAA│
00000010  41 41 41 41  41 41 41 41  41 41 41 41  41 41 41 41  │AAAA│AAAA│AAAA│AAAA│
00000020  41 41 41 41  41 41 41 41  41 41 41 41  41 41 41 41  │AAAA│AAAA│AAAA│AAAA│
00000030  41                                                  │A│
00000031
    EOS
  end

  def test_offset
    assert_lines_equal(<<-'EOS', hexdump('ELF' * 10, offset: 0x400000))
00400000  45 4c 46 45  4c 46 45 4c  46 45 4c 46  45 4c 46 45  │ELFE│LFEL│FELF│ELFE│
00400010  4c 46 45 4c  46 45 4c 46  45 4c 46 45  4c 46        │LFEL│FELF│ELFE│LF│
0040001e
    EOS
  end

  def test_style_byte
    assert_lines_equal(
      <<-'EOS',
00000000  (3f) [21] 61 62  (3f) [21] 63 64                            │(?)[!]ab│(?)[!]cd│
00000008
      EOS
      hexdump('?!ab?!cd', style: { 0x21 => ->(s) { "[#{s}]" }, 0x3f => ->(s) { "(#{s})" } })
    )
  end

  def test_style_marker
    assert_lines_equal(
      <<-'EOS',
00000000  74 65 73 74  74 65 73 74  74 65 73 74               │test☆test☆test│
0000000c
      EOS
      hexdump('testtesttest', style: { marker: ->(_) { '☆' } })
    )
  end

  def test_style_printable
    assert_lines_equal(
      <<-'EOS',
00000000  14 15 92 [65]  [35] 89 [79]                               │···[e]│[5]·[y]│
00000007
      EOS
      hexdump("\x14\x15\x92\x65\x35\x89\x79", style: { printable: ->(s) { "[#{s}]" } })
    )
  end

  def test_style_unprintable
    assert_lines_equal(
      <<-'EOS',
00000000  [14] [15] [92] 65  35 [89] 79                               │[·][·][·]e│5[·]y│
00000007
      EOS
      hexdump("\x14\x15\x92\x65\x35\x89\x79", style: { unprintable: ->(s) { "[#{s}]" } })
    )
  end

  def test_highlight
    orig_verbose = $VERBOSE
    orig_style = HIGHLIGHT_STYLE
    begin
      $VERBOSE = nil
      ::Pwnlib::Util::HexDump::ClassMethod.const_set(:HIGHLIGHT_STYLE, ->(s) { "#{s}!" })
      assert_lines_equal(<<-'EOS', hexdump('abcdefghi', highlight: 'orange'))
00000000  61! 62 63 64  65! 66 67! 68  69                        │a!bcd│e!fg!h│i│
00000009
        EOS
    ensure
      ::Pwnlib::Util::HexDump::ClassMethod.const_set(:HIGHLIGHT_STYLE, orig_style)
      $VERBOSE = orig_verbose
    end
  end

  class QQStream
    def read(n)
      'Q' * n
    end
  end

  def test_iterator_lazy
    assert_equal(<<-'EOS'.lines.map(&:chomp), hexdump_iter(QQStream.new, skip: false).take(4))
00000000  51 51 51 51  51 51 51 51  51 51 51 51  51 51 51 51  │QQQQ│QQQQ│QQQQ│QQQQ│
00000010  51 51 51 51  51 51 51 51  51 51 51 51  51 51 51 51  │QQQQ│QQQQ│QQQQ│QQQQ│
00000020  51 51 51 51  51 51 51 51  51 51 51 51  51 51 51 51  │QQQQ│QQQQ│QQQQ│QQQQ│
00000030  51 51 51 51  51 51 51 51  51 51 51 51  51 51 51 51  │QQQQ│QQQQ│QQQQ│QQQQ│
    EOS
  end
end
