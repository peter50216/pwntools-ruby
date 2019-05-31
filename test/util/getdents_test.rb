# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/util/getdents'

class GetdentsTest < MiniTest::Test
  include ::Pwnlib::Context
  include ::Pwnlib::Util::Getdents

  def test_parse
    context.local(arch: 'i386') do
      assert_equal("REG README.md\nDIR lib\n",
                   parse("\x92\x22\x0e\x01\x8f\x4a\xb3\x41" \
                         "\x18\x00\x52\x45\x41\x44\x4d\x45" \
                         "\x2e\x6d\x64\x00\x30\x00\x00\x08" \
                         "\xb5\x10\x34\x01\xff\xff\xff\x7f" \
                         "\x10\x00\x6c\x69\x62\x00\x00\x04"))
    end
    context.local(arch: 'amd64') do
      assert_equal("REG README.md\nDIR lib\n",
                   parse("\x92\x22\x0e\x01\x00\x00\x00\x00" \
                         "\x3d\xf6\x7c\x45\x8f\x4a\xb3\x41" \
                         "\x20\x00\x52\x45\x41\x44\x4d\x45" \
                         "\x2e\x6d\x64\x00\x30\x00\x00\x08" \
                         "\xb5\x10\x34\x01\x00\x00\x00\x00" \
                         "\xff\xff\xff\xff\xff\xff\xff\x7f" \
                         "\x18\x00\x6c\x69\x62\x00\x00\x04"))
    end
  end
end
