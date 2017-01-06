# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/constants/constants'
require 'pwnlib/context'

class ConstantsTest < MiniTest::Test
  include ::Pwnlib::Context
  Constants = ::Pwnlib::Constants

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal('Constant("SYS_read", 0x0)', Constants.SYS_read.inspect)
      assert_equal('__NR_arch_prctl', Constants.__NR_arch_prctl.to_s)
      assert_equal('Constant("(O_CREAT)", 0x40)', Constants.eval('O_CREAT').inspect)
      # TODO(david942j): implement 'real' Constants.eval
      # assert_equal('Constant("(O_CREAT | O_WRONLY)", 0x41)', Constants.eval('O_CREAT | O_WRONLY').inspect)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal('Constant("SYS_read", 0x3)', Constants.SYS_read.inspect)
      assert_equal('__NR_prctl', Constants.__NR_prctl.to_s)
      assert_equal('Constant("(O_CREAT)", 0x40)', Constants.eval('O_CREAT').inspect)
      # 2 < 3
      assert_operator(2, :<, Constants.SYS_read)
    end
  end
end
