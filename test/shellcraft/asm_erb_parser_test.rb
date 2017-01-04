# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class AsmErbParserTest < MiniTest::Test
  include ::Pwnlib::Shellcraft
  include ::Pwnlib::Context

  def test_arg_to_hash
    assert_equal({}, AsmErbParser.arg_to_hash(' ', []))
    assert_equal({ arg1: 1, arg2: 'str', key: true }, AsmErbParser.arg_to_hash('arg1, arg2, key: true', [1, 'str']))
    assert_equal({ arg1: 1, arg2: 'str', key: 'str' }, AsmErbParser.arg_to_hash('arg1, arg2, key: true', [1, 'str', { key: 'str' }]))
    assert_equal({ arg1: 1, args: [2, 3] }, AsmErbParser.arg_to_hash('arg1, *args', [1, 2, 3]))
  end

  def test_parse
    assert_equal("  nop\n", AsmErbParser.parse('nop', []))
    context.local(arch: 'amd64') do
      assert_equal("  mov rax, rbx\n", AsmErbParser.parse('mov', 'rax', 'rbx'))
    end
  end
end
