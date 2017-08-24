# encoding: ASCII-8BIT

::Pwnlib::Shellcraft.define(__FILE__) do |dst, src, n|
  cat "/* memcpy(#{pretty(dst)}, #{pretty(src)}, #{pretty(n)}) */"
  cat 'cld'
  cat shellcraft.amd64.setregs(rdi: dst, rsi: src, rcx: n)
  cat 'rep movsb'
end
