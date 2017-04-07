require 'pwnlib/abi'
require 'pwnlib/reg_sort'
require 'pwnlib/shellcraft/registers'

# @param [Hash{Symbol => String, Numeric}] reg_context
#   The values of each registers to be set, see examples.
# @param [Boolean] stack_allowed
#   If we can use stack for setting values. Shellcode would be shorter with +push/pop+ instructions.
#
# @example
#   puts setregs(rax: 'ebx', ebx: 'ecx', ecx: 0x123)
#   #  mov rax, rbx
#   #  mov ebx, ecx
#   #  xor ecx, ecx
#   #  mov cx, 0x123
#
#   puts setregs(rdi: 'rsi', rsi: 'rdi')
#   #  xchg rdi, rsi
#
#   puts setregs(rax: -1)
#   #  push -1
#   #  pop rax
#
#   puts setregs({rax: -1}, stack_allowed: false)
#   # mov rax, -1
::Pwnlib::Shellcraft.define(__FILE__) do |reg_context, stack_allowed: true|
  extend ::Pwnlib::RegSort
  abi = ::Pwnlib::ABI::ABI.default
  reg_context = reg_context.reject { |_, v| v.nil? }.map { |k, v| [k.to_s, v] }.to_h
  ax_str, dx_str = abi.cdq_pair
  eax = reg_context[ax_str]
  edx = reg_context[dx_str]
  cdq = false
  ev = lambda do |reg|
    return reg unless reg.is_a?(String)
    evaluate(reg)
  end
  eax = ev[eax]
  edx = ev[edx]

  # @diff
  #   The condition is wrong in python-pwntools,
  #   and here we don't care the case of edx==0xffffffff
  if eax.is_a?(Numeric) && edx.is_a?(Numeric) && edx.zero? && (eax & (1 << 31)).zero?
    cdq = true
    reg_context.delete dx_str
  end
  sorted_regs = regsort(reg_context, ::Pwnlib::Shellcraft::Registers.registers)
  if sorted_regs.empty?
    cat '/* setregs noop */'
  else
    sorted_regs.each do |how, src, dst|
      if how == 'xchg'
        cat "xchg #{src}, #{dst}"
      else
        # bug in python-pwntools, which is missing `stack_allowed`
        # pwnlib.shellcraft.setregs({'rax': 1}, stack_allowed=False)
        cat ::Pwnlib::Shellcraft.instance.mov(src, dst, stack_allowed: stack_allowed)
      end
    end
  end
  cat "cdq /* #{dx_str}=0 */" if cdq
end
