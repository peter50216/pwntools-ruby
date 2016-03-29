# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/util/packing'

class PackingTest < MiniTest::Test
  include Pwnlib::Util::Packing

  def test_pack
    assert_equal(pack(0x414243, 24, 'big', true), 'ABC')
    assert_equal(pack(0x414243, 24, 'little', true), 'CBA')

    assert_equal(pack(0x814243, 24, 'big', false), "\x81BC")
    err = assert_raises(ArgumentError) { pack(0x814243, 23, 'big', false) }
    assert_match(/does not fit/, err.message)

    assert_equal(pack(0x814243, 25, 'big', true), "\x00\x81BC")
    err = assert_raises(ArgumentError) { pack(0x814243, 24, 'big', true) }
    assert_match(/does not fit/, err.message)

    assert_equal(pack(-1, 'all', 'little', true), "\xff")
    assert_equal(pack(-256, 'all', 'big', true), "\xff\x00")
    assert_equal(pack(0xdeadbeef, 'all', 'big', false), "\xde\xad\xbe\xef")
    assert_equal(pack(0x0102030405, 'all', 'little', true), "\x05\x04\x03\x02\x01")
    assert_equal(pack(0x80000000, 'all', 'little', true), "\x00\x00\x00\x80\x00")

    err = assert_raises(ArgumentError) { pack('shik') }
    assert_match(/must be an integer/, err.message)

    assert_equal(pack(0x414243, bits: 24, endian: 'big'), 'ABC')

    err = assert_raises(ArgumentError) { pack(-514, bits: 'all', signed: 'unsigned') }
    assert_match(/Can't pack negative number/, err.message)
  end

  def test_unpack
    assert_equal(unpack("\xaa\x55", 16, 'little', false), 0x55aa)
    assert_equal(unpack("\xaa\x55", 16, 'big', false), 0xaa55)
    assert_equal(unpack("\xaa\x55", 16, 'big', true), -0x55ab)
    assert_equal(unpack("\xaa\x55", 15, 'big', true), 0x2a55)
    assert_equal(unpack("\xff\x02\x03", 'all', 'little', true), 0x0302ff)
    assert_equal(unpack("\xff\x02\x03", 'all', 'big', true), -0xfdfd)
    assert_equal(unpack("\x00\x00\x00\x80\x00", 'all', 'little', true), 0x80000000)

    err = assert_raises(ArgumentError) { unpack("\xff\xff", 8, 'big', false) }
    assert_match(/does not match/, err.message)

    assert_equal(unpack('ABC', bits: 'all', endian: 'big', signed: false), 0x414243)
  end
end
