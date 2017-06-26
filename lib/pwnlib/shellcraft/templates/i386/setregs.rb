# encoding: ASCII-8BIT

::Pwnlib::Shellcraft.define(__FILE__) do |reg_context, stack_allowed: true|
  context.local(arch: 'i386') do
    cat shellcraft.x86.setregs(reg_context, stack_allowed: stack_allowed)
  end
end
