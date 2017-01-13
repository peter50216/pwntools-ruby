require 'pwnlib/shellcraft/shellcraft'
::Pwnlib::Shellcraft.define('i386.nop') do
  cat 'nop'
end
