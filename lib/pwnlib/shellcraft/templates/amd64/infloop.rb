require 'pwnlib/shellcraft/shellcraft'
Pwnlib::Shellcraft.define('amd64.infloop') do
  cat 'jmp $'
end
