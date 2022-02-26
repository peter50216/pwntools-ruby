# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'test_helper'

require 'pwnlib/abi'
require 'pwnlib/runner'
require 'pwnlib/shellcraft/shellcraft'

class RunnerTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    linux_only 'Runner can only be used on Linux'
  end

  def shellcraft
    ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_run_assembly
    %w[i386 amd64].each do |arch|
      context.local(arch: arch) do
        r = ::Pwnlib::Runner.run_assembly(
          shellcraft.pushstr('run_assembly') +
          shellcraft.syscall('SYS_write', 1, ::Pwnlib::ABI::ABI.default.stack_pointer, 12) +
          shellcraft.exit(0)
        )
        assert_equal('run_assembly', r.recvn(12))
        # Test if reach EOF
        assert_raises(::Pwnlib::Errors::EndOfTubeError) { r.recv }
      end
    end
  end
end
