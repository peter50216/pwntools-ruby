require 'test_helper'
require 'pwnlib/context'

class ContextTest < MiniTest::Test
  include Pwnlib::Context

  def test_update
    context.update(arch: 'arm', os: 'windows')
    assert_equal(context.arch, 'arm')
    assert_equal(context.os, 'windows')
  end

  def test_local
    context.timeout = 1
    assert_equal(context.timeout, 1)

    context.local(timeout: 2) do
      assert_equal(context.timeout, 2)
      context.timeout = 3
      assert_equal(context.timeout, 3)
    end

    assert_equal(context.timeout, 1)
  end

  def test_clear
    default_arch = context.arch
    context.arch = 'arm'
    context.clear
    assert_equal(context.arch, default_arch)
  end

  def test_arch
    context.arch = 'mips'
    assert_equal(context.arch, 'mips')

    err = assert_raises(ArgumentError) { context.arch = 'shik' }
    assert_match(/arch must be one of/, err.message)
    assert_equal(context.arch, 'mips')

    context.clear
    assert_equal(context.bits, 32)
    context.arch = 'powerpc64'
    assert_equal(context.bits, 64)
    assert_equal(context.endian, 'big')
  end

  def test_bits
    context.bits = 64
    assert_equal(context.bits, 64)

    err = assert_raises(ArgumentError) { context.bits = 0 }
    assert_match(/bits must be > 0/, err.message)
  end

  def test_bytes
    context.bytes = 8
    assert_equal(context.bits, 64)
    assert_equal(context.bytes, 8)

    context.bits = 32
    assert_equal(context.bytes, 4)
  end

  def test_endian
    context.endian = 'le'
    assert_equal(context.endian, 'little')

    context.endian = 'big'
    assert_equal(context.endian, 'big')

    err = assert_raises(ArgumentError) { context.endian = 'SUPERBIG' }
    assert_match(/endian must be one of/, err.message)
  end

  def test_log_level
    context.log_level = 'error'
    assert_equal(context.log_level, Logger::ERROR)

    context.log_level = 514
    assert_equal(context.log_level, 514)

    err = assert_raises(ArgumentError) { context.log_level = 'BOOM' }
    assert_match(/log_level must be an integer or one of/, err.message)
  end

  def test_os
    context.os = 'windows'
    assert_equal(context.os, 'windows')

    err = assert_raises(ArgumentError) { context.os = 'deepblue' }
    assert_match(/os must be one of/, err.message)
  end

  def test_signed
    context.signed = true
    assert_equal(context.signed, true)

    context.signed = 'unsigned'
    assert_equal(context.signed, false)

    err = assert_raises(ArgumentError) { context.signed = 'partial' }
    assert_match(/signed must be boolean or one of/, err.message)
  end

  def test_timeout
    context.timeout = 123
    assert_equal(context.timeout, 123)
  end

  def test_newline
    context.newline = "\r\n"
    assert_equal(context.newline, "\r\n")
  end
end
