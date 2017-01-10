require 'pwnlib/shellcraft/shellcraft'
Pwnlib::Shellcraft.define('i386.infloop') do
  cat 'jmp $'
end
