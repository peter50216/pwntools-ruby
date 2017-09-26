# encoding: ASCII-8BIT

::Pwnlib::Shellcraft.define(__FILE__) do |return_value = nil|
  cat shellcraft.amd64.mov('rax', return_value) if return_value
  cat 'ret'
end
