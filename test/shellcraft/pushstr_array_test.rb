# encoding: ASCII-8BIT
require 'test_helper'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/context'

class PushstrArrayTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.pushstr_array('rcx', ['A']))
  /* push argument array ["A\x00"] */
  /* push "A\x00" */
  push 0x41
  xor ecx, ecx /* 0 */
  push rcx /* null terminate */
  push 8
  pop rcx
  add rcx, rsp
  push rcx /* "A\x00" */
  mov rcx, rsp
      EOS
      assert_equal(<<-'EOS', @shellcraft.pushstr_array('rsp', ['sh', '-c', 'echo pusheen']))
  /* push argument array ["sh\x00", "-c\x00", "echo pusheen\x00"] */
  /* push "sh\x00-c\x00echo pusheen\x00" */
  push 0x1010101 ^ 0x6e65
  xor dword ptr [rsp], 0x1010101
  mov rax, 0x6568737570206f68
  push rax
  mov rax, 0x101010101010101
  push rax
  mov rax, 0x101010101010101 ^ 0x636500632d006873
  xor [rsp], rax
  xor esp, esp /* 0 */
  push rsp /* null terminate */
  push 0xe
  pop rsp
  add rsp, rsp
  push rsp /* "echo pusheen\x00" */
  push 0x13
  pop rsp
  add rsp, rsp
  push rsp /* "-c\x00" */
  push 0x18
  pop rsp
  add rsp, rsp
  push rsp /* "sh\x00" */
  /* moving rsp into rsp, but this is a no-op */
      EOS
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal(<<-'EOS', @shellcraft.pushstr_array('esp', ['sh', '-c', 'echo pusheen']))
  /* push argument array ["sh\x00", "-c\x00", "echo pusheen\x00"] */
  /* push "sh\x00-c\x00echo pusheen\x00" */
  push 0x1010101
  xor dword ptr [esp], 0x1010101 ^ 0x6e65
  push 0x65687375
  push 0x70206f68
  push 0x1010101
  xor dword ptr [esp], 0x1010101 ^ 0x63650063
  push 0x1010101
  xor dword ptr [esp], 0x1010101 ^ 0x2d006873
  xor esp, esp /* 0 */
  push esp /* null terminate */
  push 9 /* mov esp, '\n' */
  pop esp
  inc esp
  add esp, esp
  push esp /* "echo pusheen\x00" */
  push 0xb
  pop esp
  add esp, esp
  push esp /* "-c\x00" */
  push 0xc
  pop esp
  add esp, esp
  push esp /* "sh\x00" */
  /* moving esp into esp, but this is a no-op */
      EOS
    end
  end
end
