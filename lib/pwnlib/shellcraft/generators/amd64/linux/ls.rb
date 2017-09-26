# encoding: ASCII-8BIT

::Pwnlib::Shellcraft.define(__FILE__) do |*args|
  context.local(arch: 'amd64') do
    cat shellcraft.x86.linux.ls(*args)
  end
end
