# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

class ShTest < MiniTest::Test
  include ::Pwnlib::Context

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def test_amd64
    context.local(arch: 'amd64') do
      assert_equal(<<-'EOS', @shellcraft.sh)
  /* push "/bin///sh\x00" */
  push 0x68
  mov rax, 0x732f2f2f6e69622f
  push rax

  /* call execve("rsp", 0, 0) */
  push 0x3b /* (SYS_execve) */
  pop rax
  mov rdi, rsp
  xor esi, esi /* 0 */
  cdq /* rdx=0 */
  syscall
      EOS
      assert_equal(<<-'EOS', @shellcraft.sh(argv: true))
  /* push argument array ["sh\x00"] */
  /* push "sh\x00" */
  push 0x1010101 ^ 0x6873
  xor dword ptr [rsp], 0x1010101
  xor esi, esi /* 0 */
  push rsi /* null terminate */
  push 8
  pop rsi
  add rsi, rsp
  push rsi /* "sh\x00" */
  mov rsi, rsp

  /* push "/bin///sh\x00" */
  push 0x68
  mov rax, 0x732f2f2f6e69622f
  push rax

  /* call execve("rsp", "rsi", 0) */
  push 0x3b /* (SYS_execve) */
  pop rax
  mov rdi, rsp
  cdq /* rdx=0 */
  syscall
      EOS
      assert_equal(<<-'EOS', @shellcraft.sh(argv: ['sh', '-c', 'echo pusheen']))
  /* push argument array ["sh\x00", "-c\x00", "echo pusheen\x00"] */
  /* push "sh\x00-c\x00echo pusheen\x00" */
  push 0x1010101 ^ 0x6e65
  xor dword ptr [rsp], 0x1010101
  mov rax, 0x6568737570206f68
  push rax
  mov rax, 0x101010101010101
  push rax
  mov rax, 0x626401622c016972 /* 0x101010101010101 ^ 0x636500632d006873 */
  xor [rsp], rax
  xor esi, esi /* 0 */
  push rsi /* null terminate */
  push 0xe
  pop rsi
  add rsi, rsp
  push rsi /* "echo pusheen\x00" */
  push 0x13
  pop rsi
  add rsi, rsp
  push rsi /* "-c\x00" */
  push 0x18
  pop rsi
  add rsi, rsp
  push rsi /* "sh\x00" */
  mov rsi, rsp

  /* push "/bin///sh\x00" */
  push 0x68
  mov rax, 0x732f2f2f6e69622f
  push rax

  /* call execve("rsp", "rsi", 0) */
  push 0x3b /* (SYS_execve) */
  pop rax
  mov rdi, rsp
  cdq /* rdx=0 */
  syscall
      EOS
    end
  end

  def test_i386
    context.local(arch: 'i386') do
      assert_equal(<<-'EOS', @shellcraft.sh)
  /* push "/bin///sh\x00" */
  push 0x68
  push 0x732f2f2f
  push 0x6e69622f

  /* call execve("esp", 0, 0) */
  push 0xb /* (SYS_execve) */
  pop eax
  mov ebx, esp
  xor ecx, ecx /* 0 */
  cdq /* edx=0 */
  int 0x80
      EOS
      assert_equal(@shellcraft.execve('/bin///sh', ['sh'], 0), @shellcraft.sh(argv: true))
      assert_equal(@shellcraft.execve('/bin///sh', ['sh', '-c', 'echo pusheen'], 0),
                   @shellcraft.sh(argv: ['sh', '-c', 'echo pusheen']))
    end
  end
end
