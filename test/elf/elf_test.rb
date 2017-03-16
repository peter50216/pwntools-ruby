# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/elf/elf'

class ELFTest < MiniTest::Test
  def setup
    path = File.join(__dir__, '..', 'data', 'victim32')
    @elf = ::Pwnlib::ELF::ELF.new(path)
    Rainbow.enabled = false
  end

  def test_checksec
    assert_equal <<-EOS.strip, @elf.checksec
RELRO:    No RELRO
Stack:    No canary found
NX:       NX enabled
PIE:      No PIE
    EOS
  end
end
