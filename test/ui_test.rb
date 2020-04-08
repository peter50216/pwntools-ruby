# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'stringio'

require 'test_helper'

require 'pwnlib/ui'

class UITest < MiniTest::Test
  def test_pause
    hook_stdin(StringIO.new("\n")) do
      assert_output(<<-EOS) { log_stdout { ::Pwnlib::UI.pause } }
[*] Paused (press enter to continue)
      EOS
    end
  end
end
