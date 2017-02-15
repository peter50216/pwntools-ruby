require 'pwnlib/context'
require 'pwnlib/shellcraft/shellcraft'

::Pwnlib::Shellcraft.define(__FILE__) do |reg, array|
  ::Pwnlib::Context.context.local(arch: 'amd64') do
    cat ::Pwnlib::Shellcraft.instance.x86.pushstr_array(reg, array)
  end
end
