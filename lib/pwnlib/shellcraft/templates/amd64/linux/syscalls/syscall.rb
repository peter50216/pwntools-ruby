::Pwnlib::Shellcraft.define(__FILE__) do |*arguments|
  context.local(arch: 'amd64') do
    cat shellcraft.x86.linux.syscalls.syscall(*arguments)
  end
end
