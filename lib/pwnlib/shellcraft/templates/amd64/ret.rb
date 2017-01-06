require 'pwnlib/shellcraft/shellcraft'
def ret(return_value = nil)
  cat ::Pwnlib::Shellcraft.amd64.mov('rax', return_value) unless return_value.nil?
  cat 'ret'
end
