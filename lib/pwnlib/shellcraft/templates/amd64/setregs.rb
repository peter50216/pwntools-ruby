require 'pwnlib/shellcraft/registers'
require 'pwnlib/reg_sort'
require 'pwnlib/shellcraft/shellcraft'

::Pwnlib::Shellcraft.define('amd64.setregs') do |reg_context, stack_allowed: true|
  extend ::Pwnlib::RegSort::ClassMethods
  amd64 = ::Pwnlib::Shellcraft.instance.amd64
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

  # @diff
  #   The condition is wrong in python-pwntools,
  #   and here we don't care the case of edx==0xffffffff
  if eax.is_a?(Numeric) && edx.is_a?(Numeric) && edx.zero? && (eax & (1 << 31)).zero?
    cdq = true
    reg_context.delete 'rdx'
  end
  sorted_regs = regsort(reg_context, ::Pwnlib::Shellcraft::Registers::AMD64)
  if sorted_regs.empty?
    cat '/* setregs noop */'
  else
    sorted_regs.each do |how, src, dst|
      if how == 'xchg'
        cat "xchg #{src}, #{dst}"
      else
        # bug in python-pwntools, which is missing `stack_allowed`
        # pwnlib.shellcraft.amd64.setregs({'rax': 1}, stack_allowed=False)
        cat amd64.mov(src, dst, stack_allowed: stack_allowed)
      end
    end
  end
  cat 'cdq /* rdx=0 */' if cdq
end
