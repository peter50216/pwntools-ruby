require 'pwnlib/shellcraft/shellcraft'

::Pwnlib::Shellcraft.define(__FILE__) do |reg_context, stack_allowed: true|
  ::Pwnlib::Context.context.local(arch: 'i386') do
    cat ::Pwnlib::Shellcraft.instance.x86.setregs(reg_context, stack_allowed: stack_allowed)
  end
end
