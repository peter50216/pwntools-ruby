require 'pwnlib/shellcraft/registers'
require 'pwnlib/reg_sort'
require 'pwnlib/shellcraft/shellcraft'

::Pwnlib::Shellcraft.define(__FILE__) do |reg_context, stack_allowed: true|
  extend ::Pwnlib::RegSort::ClassMethods
  i386 = ::Pwnlib::Shellcraft.instance.i386
  reg_context = reg_context.reject { |_, v| v.nil? }.map { |k, v| [k.to_s, v] }.to_h
  eax = reg_context['eax']
  edx = reg_context['edx']
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

  # @diff
  #   The condition is wrong in python-pwntools,
  #   and here we don't care the case of edx==0xffffffff
  if eax.is_a?(Numeric) && edx.is_a?(Numeric) && edx.zero? && (eax & (1 << 31)).zero?
    cdq = true
    reg_context.delete 'edx'
  end
  sorted_regs = regsort(reg_context, ::Pwnlib::Shellcraft::Registers::I386)
  if sorted_regs.empty?
    cat '/* setregs noop */'
  else
    sorted_regs.each do |how, src, dst|
      if how == 'xchg'
        cat "xchg #{src}, #{dst}"
      else
        # bug in python-pwntools, which is missing `stack_allowed`
        # pwnlib.shellcraft.i386.setregs({'rax': 1}, stack_allowed=False)
        cat i386.mov(src, dst, stack_allowed: stack_allowed)
      end
    end
  end
  cat 'cdq /* edx=0 */' if cdq
end
