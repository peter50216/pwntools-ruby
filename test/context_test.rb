require 'test_helper'
require 'pwnlib/context'

class ContextTest < MiniTest::Test
  include Pwnlib::Context

  def test_update
    context.update(arch: 'arm', os: 'windows')
    assert_equal('arm', context.arch)
    assert_equal('windows', context.os)
  end

  def test_local
    context.timeout = 1
    assert_equal(1, context.timeout)

    context.local(timeout: 2) do
      assert_equal(2, context.timeout)
      context.timeout = 3
      assert_equal(3, context.timeout)
    end

    assert_equal(1, context.timeout)
  end

  def test_clear
    default_arch = context.arch
    context.arch = 'arm'
    context.clear
    assert_equal(default_arch, context.arch)
  end

  def test_arch
    context.arch = 'mips'
    assert_equal('mips', context.arch)

    err = assert_raises(ArgumentError) { context.arch = 'shik' }
    assert_match(/arch must be one of/, err.message)
    assert_equal('mips', context.arch)

    context.clear
    assert_equal(32, context.bits)
    context.arch = 'powerpc64'
    assert_equal(64, context.bits)
    assert_equal('big', context.endian)
  end

  def test_bits
    context.bits = 64
    assert_equal(64, context.bits)

    err = assert_raises(ArgumentError) { context.bits = 0 }
    assert_match(/bits must be > 0/, err.message)
  end

  def test_bytes
    context.bytes = 8
    assert_equal(64, context.bits)
    assert_equal(8, context.bytes)

    context.bits = 32
    assert_equal(4, context.bytes)
  end

  def test_endian
    context.endian = 'le'
    assert_equal('little', context.endian)

    context.endian = 'big'
    assert_equal('big', context.endian)

    err = assert_raises(ArgumentError) { context.endian = 'SUPERBIG' }
    assert_match(/endian must be one of/, err.message)
  end

  def test_log_level
    context.log_level = 'error'
    assert_equal(Logger::ERROR, context.log_level)

    context.log_level = 514
    assert_equal(514, context.log_level)

    err = assert_raises(ArgumentError) { context.log_level = 'BOOM' }
    assert_match(/log_level must be an integer or one of/, err.message)
  end

  def test_os
    context.os = 'windows'
    assert_equal('windows', context.os)

    err = assert_raises(ArgumentError) { context.os = 'deepblue' }
    assert_match(/os must be one of/, err.message)
  end

  def test_signed
    context.signed = true
    assert_equal(true, context.signed)

    context.signed = 'unsigned'
    assert_equal(false, context.signed)

    err = assert_raises(ArgumentError) { context.signed = 'partial' }
    assert_match(/signed must be boolean or one of/, err.message)
  end

  def test_timeout
    context.timeout = 123
    assert_equal(123, context.timeout)
  end

  def test_newline
    context.newline = "\r\n"
    assert_equal("\r\n", context.newline)
  end

  def test_to_s
    assert_match(/\APwnlib::Context::ContextType\(.+\)\Z/, context.to_s)
  end
end
