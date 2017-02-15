# encoding: ASCII-8BIT
require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

::Pwnlib::Shellcraft.define(__FILE__) do |path, argv, envp|
  ::Pwnlib::Context.context.local(arch: 'i386') do
    cat ::Pwnlib::Shellcraft.instance.x86.linux.syscalls.execve(path, argv, envp)
  end
end
