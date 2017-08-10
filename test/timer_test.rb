# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/timer'

class TimerTest < MiniTest::Test
  include ::Pwnlib

  def test_basic
    t = Timer.new
    class << t
      attr_writer :deadline
    end

    assert_nil(t.started?)
    assert_nil(t.active?)
    t.timeout = nil
    t.deadline = :forever
    exception = assert_raises(RuntimeError) { t.timeout = nil }
    assert_equal("Can't change timeout when countdown", exception.message)
    exception = assert_raises(RuntimeError) { t.countdown(0.1) {} }
    assert_equal('Nested countdown not permitted', exception.message)
  end
end
