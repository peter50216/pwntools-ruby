require 'pwnlib/shellcraft/shellcraft'
::Pwnlib::Shellcraft.define('amd64.nop') do
  cat 'nop'
end
