# encoding: ASCII-8BIT

::Pwnlib::Shellcraft.define(__FILE__) do |reg, array|
  context.local(arch: 'i386') do
    cat shellcraft.x86.pushstr_array(reg, array)
  end
end
