# encoding: ASCII-8BIT

::Pwnlib::Shellcraft.define(__FILE__) do |path, argv, envp|
  context.local(arch: 'amd64') do
    cat shellcraft.x86.linux.syscalls.execve(path, argv, envp)
  end
end
