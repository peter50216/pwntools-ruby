::Pwnlib::Shellcraft.define(__FILE__) do |*arguments|
  context.local(arch: 'i386') do
    cat shellcraft.x86.linux.syscalls.syscall(*arguments)
  end
end
