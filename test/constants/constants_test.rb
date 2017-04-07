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
      assert_equal('Constant("(O_CREAT | O_WRONLY)", 0x41)', Constants.eval('O_CREAT | O_WRONLY').inspect)
      err = assert_raises(NameError) { Constants.eval('rax') }
      assert_equal('no value provided for variables: rax', err.message)
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal('Constant("SYS_read", 0x3)', Constants.SYS_read.inspect)
      assert_equal('__NR_prctl', Constants.__NR_prctl.to_s)
      assert_equal('Constant("(O_CREAT)", 0x40)', Constants.eval('O_CREAT').inspect)
      assert_equal(0x40, Constants.method(:O_CREAT).call.to_i)
      # 2 < 3
      assert_operator(2, :<, Constants.SYS_read)
    end
  end
end
