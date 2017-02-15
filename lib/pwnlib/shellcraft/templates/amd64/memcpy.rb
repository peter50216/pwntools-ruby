require 'pwnlib/shellcraft/shellcraft'
::Pwnlib::Shellcraft.define(__FILE__) do |dst, src, n|
  cat "/* memcpy(#{pretty(dst)}, #{pretty(src)}, #{pretty(n)}) */"
  cat 'cld'
  cat ::Pwnlib::Shellcraft.instance.amd64.setregs(rdi: dst, rsi: src, rcx: n)
  cat 'rep movsb'
end
