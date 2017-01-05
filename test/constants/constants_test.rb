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
    # test coerce
    assert_operator(0, :==, Constant.new('ZERO', 0))
    assert_operator(a1, :==, Constant.new('a', 1))
    assert_equal(false, a1 == Constant.new('b', 1))
    assert_equal(false, a1 == 'a')
    assert_equal(3, a1 | Constant.new('a', 2))
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal('Constant("SYS_read", 0x0)', send(:SYS_read).inspect)
      assert_equal('__NR_arch_prctl', send(:__NR_arch_prctl).to_s)
      assert_equal('Constant("(O_CREAT)", 0x40)', ::Pwnlib::Constants.eval('O_CREAT').inspect)
      # TODO(david942j): implement 'real' Constants.eval
      # assert_equal('Constant("(O_CREAT | O_WRONLY)", 0x41)', ::Pwnlib::Constants.eval('O_CREAT | O_WRONLY').inspect)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal('Constant("SYS_read", 0x3)', send(:SYS_read).inspect)
      assert_equal('__NR_prctl', send(:__NR_prctl).to_s)
      assert_equal('Constant("(O_CREAT)", 0x40)', ::Pwnlib::Constants.eval('O_CREAT').inspect)
      # 2 < 3
      assert_operator(2, :<, send(:SYS_read))
    end
  end
end
