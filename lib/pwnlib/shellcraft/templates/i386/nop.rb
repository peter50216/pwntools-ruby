require 'pwnlib/shellcraft/shellcraft'
::Pwnlib::Shellcraft.define(__FILE__) do
  cat 'nop'
end
