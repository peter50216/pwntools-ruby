require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

::Pwnlib::Shellcraft.define(__FILE__) do |*arguments|
  ::Pwnlib::Context.context.local(arch: 'amd64') do
    cat ::Pwnlib::Shellcraft.instance.x86.linux.syscalls.syscall(*arguments)
  end
end
