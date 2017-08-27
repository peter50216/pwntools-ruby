# encoding: ASCII-8BIT

::Pwnlib::Shellcraft.define(__FILE__) do |argv: false|
  context.local(arch: 'i386') do
    cat shellcraft.x86.linux.sh(argv: argv)
  end
end
