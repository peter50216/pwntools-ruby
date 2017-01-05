# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/constants/constants'
require 'pwnlib/constants/constant'

class ConstantsTest < MiniTest::Test
  include Pwnlib::Constants::ClassMethod
  Constant = ::Pwnlib::Constants::Constant

  def test_constant_methods
    a1 = Constant.new('a', 1)
    assert_equal(9, Constant.new('c', 9).to_i)
    assert_equal(3, a1 | 2)
    assert_operator(Constant.new('ZERO', 0), :==, 0)
    assert_operator(a1, :==, Constant.new('a', 1))
    assert_equal(false, a1 == Constant.new('b', 1))
    assert_equal(false, a1 == 'a')
    assert_equal(true, a1.is_a?(Fixnum))
    assert_equal(true, a1.is_a?(Constant))
    assert_equal(false, a1.is_a?(String))
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal('Constant("SYS_read", 0)', send(:SYS_read).inspect)
      assert_equal('__NR_arch_prctl', send(:__NR_arch_prctl).to_s)
      assert_equal('Constant("O_CREAT", 0x40)', ::Pwnlib::Constants.eval('O_CREAT').inspect)
      # TODO(david942j): implement 'real' Constants.eval
      # assert_equal('Constant("O_CREAT | O_WRONLY", 0x41)', ::Pwnlib::Constants.eval('O_CREAT | O_WRONLY').inspect)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal('Constant("SYS_read", 0x3)', send(:SYS_read).inspect)
      assert_equal('__NR_prctl', send(:__NR_prctl).to_s)
      assert_equal('Constant("O_CREAT", 0x40)', ::Pwnlib::Constants.eval('O_CREAT').inspect)
    end
  end
end
