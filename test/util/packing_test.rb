# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/util/packing'

class PackingTest < MiniTest::Test
  include ::Pwnlib::Util::Packing::ClassMethod

  def test_pack
    assert_equal('ABC',
                 pack(0x414243, bits: 24, endian: 'big', signed: true))
    assert_equal('CBA',
                 pack(0x414243, bits: 24, endian: 'little', signed: true))

    assert_equal("\x81BC", pack(0x814243, bits: 24, endian: 'big', signed: false))
    err = assert_raises(ArgumentError) do
      pack(0x814243, bits: 23, endian: 'big', signed: false)
    end
    assert_match(/does not fit/, err.message)

    assert_equal("\x00\x81BC", pack(0x814243, bits: 25, endian: 'big', signed: true))
    err = assert_raises(ArgumentError) do
      pack(0x814243, bits: 24, endian: 'big', signed: true)
    end
    assert_match(/does not fit/, err.message)

    assert_equal("\xff", pack(-1, bits: 'all', endian: 'little', signed: true))
    assert_equal("\xff\x00", pack(-256, bits: 'all', endian: 'big', signed: true))
    assert_equal("\xde\xad\xbe\xef",
                 pack(0xdeadbeef, bits: 'all', endian: 'big', signed: false))
    assert_equal("\x05\x04\x03\x02\x01",
                 pack(0x0102030405, bits: 'all', endian: 'little', signed: true))
    assert_equal("\x00\x00\x00\x80\x00",
                 pack(0x80000000, bits: 'all', endian: 'little', signed: true))

    assert_equal('ABC', pack(0x414243, bits: 24, endian: 'big'))

    err = assert_raises(ArgumentError) { pack(-514, bits: 'all', signed: 'unsigned') }
    assert_match(/Can't pack negative number/, err.message)
  end

  def test_unpack
    assert_equal(0x55aa,
                 unpack("\xaa\x55", bits: 16, endian: 'little', signed: false))
    assert_equal(0xaa55,
                 unpack("\xaa\x55", bits: 16, endian: 'big', signed: false))
    assert_equal(-0x55ab, unpack("\xaa\x55", bits: 16, endian: 'big', signed: true))
    assert_equal(0x2a55, unpack("\xaa\x55", bits: 15, endian: 'big', signed: true))
    assert_equal(0x0302ff,
                 unpack("\xff\x02\x03", bits: 'all', endian: 'little', signed: true))
    assert_equal(-0xfdfd, unpack("\xff\x02\x03", bits: 'all', endian: 'big', signed: true))
    assert_equal(0x80000000,
                 unpack("\x00\x00\x00\x80\x00", bits: 'all', endian: 'little', signed: true))

    err = assert_raises(ArgumentError) do
      unpack("\xff\xff", bits: 8, endian: 'big', signed: false)
    end
    assert_match(/does not match/, err.message)

    assert_equal(0x414243, unpack('ABC', bits: 'all', endian: 'big', signed: false))
  end

  def test_unpack_many
    assert_equal([0x55aa, 0x33cc],
                 unpack_many("\xaa\x55\xcc\x33", bits: 16, endian: 'little', signed: false))
    assert_equal([0xaa55, 0xcc33],
                 unpack_many("\xaa\x55\xcc\x33", bits: 16, endian: 'big', signed: false))
    assert_equal([-0x55ab, -0x33cd],
                 unpack_many("\xaa\x55\xcc\x33", bits: 16, endian: 'big', signed: true))
    assert_equal([0x0302ff],
                 unpack_many("\xff\x02\x03", bits: 'all', endian: 'little', signed: true))
    assert_equal([-0xfdfd],
                 unpack_many("\xff\x02\x03", bits: 'all', endian: 'big', signed: true))

    err = assert_raises(ArgumentError) { unpack_many('ABCD', bits: 12) }
    assert_match(/bits must be a multiple of 8/, err.message)

    err = assert_raises(ArgumentError) { unpack_many('ABC', bits: 16) }
    assert_match(/must be a multiple of bytes/, err.message)

    assert_equal([0x41, 0x42, 0x43, 0x44], unpack_many('ABCD', bits: 8))
    assert_equal([0x4142, 0x4344],
                 unpack_many('ABCD', bits: 16, endian: 'big', signed: 'signed'))
    assert_equal([-2, -1],
                 unpack_many("\xff\xfe\xff\xff", bits: 16, endian: 'big', signed: 'signed'))
  end

  def test_ps
    assert_equal('A', p8(0x41))
    assert_equal('BA', p16(0x4142))
    assert_equal('DCBA', p32(0x41424344))
    assert_equal('4321DCBA', p64(0x4142434431323334))

    assert_equal('AB', p16(0x4142, endian: 'big'))
    assert_equal('ABCD', p32(0x41424344, endian: 'big'))
    assert_equal('ABCD1234', p64(0x4142434431323334, endian: 'big'))

    assert_equal("\xff\xff\xff\xff", p32(-1))
  end

  def test_us
    assert_equal(0x41, u8('A'))
    assert_equal(0x4142, u16('BA'))
    assert_equal(0x41424344, u32('DCBA'))
    assert_equal(0x4142434431323334, u64('4321DCBA'))

    assert_equal(0x4142, u16('AB', endian: 'big'))
    assert_equal(0x41424344, u32('ABCD', endian: 'big'))
    assert_equal(0x4142434431323334, u64('ABCD1234', endian: 'big'))

    assert_equal(0xFFFFFFFF, u32("\xff\xff\xff\xff", signed: false))
    assert_equal(-1, u32("\xff\xff\xff\xff", signed: true))
  end

  def test_up_rand
    srand(217)
    [8, 16, 32, 64].each do |sz|
      u = ->(*x) { public_send("u#{sz}", *x) }
      p = ->(*x) { public_send("p#{sz}", *x) }
      100.times do
        limit = (1 << sz)
        val = rand(0...limit)
        assert_equal(val, u[p[val, signed: false], signed: false])

        limit = (1 << (sz - 1))
        val = rand(-limit...limit)
        assert_equal(val, u[p[val, signed: true], signed: true])

        rs = Array.new(sz / 8) { rand(256).chr }.join
        assert_equal(rs, p[u[rs, signed: false], signed: false])
        assert_equal(rs, p[u[rs, signed: true], signed: true])
      end
    end
  end

  def test_make_packer
    p = context.local(bits: 32, signed: 'no') { make_packer(endian: 'be') }
    assert_equal("\x00\x00\x00A", p[0x41])

    context.local(bits: 64, endian: 'le', signed: true) do
      assert_equal("\x00\x00\x00A", p[0x41])
    end

    p = make_packer(bits: 24)
    assert_equal("B\x00\x00", p[0x42])
  end

  def test_make_unpacker
    u = context.local(bits: 32, signed: 'no') { make_unpacker(endian: 'be') }
    assert_equal(0x41, u["\x00\x00\x00A"])

    context.local(bits: 64, endian: 'le', signed: true) do
      assert_equal(0x41, u["\x00\x00\x00A"])
    end

    u = make_unpacker(bits: 24)
    assert_equal(0x42, u["B\x00\x00"])
  end

  def test_flat
    assert_equal("\x01\x00testABABABABABAB",
                 flat(1, 'test', [[['AB'] * 2] * 3], endian: 'le', bits: 16))
    assert_equal('234', flat([1, [2, 3]]) { |x| (x + 1).to_s })

    err = assert_raises(ArgumentError) { flat(1.23) }
    assert_match(/flat does not support values of type/, err.message)
  end
end
