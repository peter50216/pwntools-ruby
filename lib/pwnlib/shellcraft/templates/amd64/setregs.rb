require 'pwnlib/shellcraft/shellcraft'
Shellcraft = ::Pwnlib::Shellcraft
require 'pwnlib/shellcraft/registers'
Registers = ::Pwnlib::Shellcraft::Registers
require 'pwnlib/reg_sort'
extend ::Pwnlib::RegSort::ClassMethod
def setregs(reg_context, stack_allowed: true)
  reg_context = reg_context.reject { |_, v| v.nil? }.map { |k, v| [k.to_s, v] }.to_h
  eax = reg_context['rax']
  edx = reg_context['rdx']
  cdq = false
  ev = lambda do |reg|
    next reg unless reg.is_a?(String)
    begin
      evaluate(reg)
    rescue NameError
      reg
    end
  end
  eax = ev[eax]
  edx = ev[edx]

  if eax.is_a?(Numeric) && edx.is_a?(Numeric) && eax >> 63 == edx
    cdq = true
    reg_context.delete 'rdx'
  end
  sorted_regs = regsort(reg_context, Registers::AMD64)
  if sorted_regs.empty?
    cat '/* setregs noop */'
  else
    sorted_regs.each do |how, src, dst|
      if how == 'xchg'
        cat "xchg #{src}, #{dst}"
      else
        # bug in python-pwntools, which missing `stack_allowed`
        # pwnlib.shellcraft.amd64.setregs({'rax': 1}, stack_allowed=False)
        # TODO(david942j): should be amd64.mov
        cat Shellcraft.mov(src, dst, stack_allowed: stack_allowed)
      end
    end
  end
  cat 'cdq /* rdx=0 */' if cdq
end
