# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/timer'

class TimerTest < MiniTest::Test
  include ::Pwnlib

  def test_countdown
    t = Timer.new
    refute(t.started?)
    refute(t.active?)
    assert_equal('DARKHH QQ', t.countdown(0.1) { 'DARKHH QQ' })
    exception = assert_raises(RuntimeError) { t.countdown(0.1) { t.countdown(0.1) {} } }
    assert_equal('Nested countdown not permitted', exception.message)
    t.timeout = 0.514
    exception = assert_raises(RuntimeError) { t.countdown(0.1) { t.timeout = :forever } }
    assert_equal("Can't change timeout when countdown", exception.message)
    t.countdown(0.1) { assert(t.started?) }
    t.countdown(0.1) { assert(t.active?) }
  end
end
