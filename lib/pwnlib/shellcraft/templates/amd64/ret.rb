require 'pwnlib/shellcraft/shellcraft'
::Pwnlib::Shellcraft.define(__FILE__) do |return_value = nil|
  shellcraft = ::Pwnlib::Shellcraft.instance
  cat shellcraft.amd64.mov('rax', return_value) unless return_value.nil?
  cat 'ret'
end
