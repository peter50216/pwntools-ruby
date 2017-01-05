# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/constants/constants'

class ConstantsTest < MiniTest::Test
  include Pwnlib::Constants::ClassMethod
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
