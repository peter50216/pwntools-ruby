# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/registers'

class RegistersTest < MiniTest::Test
  include Pwnlib::Shellcraft::Registers::ClassMethod

  def test_get_register
    assert_instance_of(Pwnlib::Shellcraft::Registers::Register, get_register('rdi'))
    assert_nil(get_register('meow'))
  end

  def test_regtsiter?
    assert_equal(true, register?('ax'))
    assert_equal(true, register?('r8'))
    assert_equal(true, register?('r15b'))
    assert_equal(true, register?('r15w'))
    assert_equal(false, register?('xdd'))
    assert_equal(false, register?(''))
  end

  def test_register
    assert_equal(8, get_register('rdi').bytes)
    assert_equal(16, get_register('ax').bits)
    assert_equal('r10d', get_register('r10d').name)
    assert_equal('r10d', get_register('r10d').to_s)
    assert_equal('Register(r10d)', get_register('r10d').inspect)
  end
end
