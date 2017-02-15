require 'pwnlib/shellcraft/shellcraft'
::Pwnlib::Shellcraft.define(__FILE__) do
  cat <<EOS
    pop rdi
    pop rsi
    pop rbp
    pop rbx /* add rsp, 8 */
    pop rbx
    pop rdx
    pop rcx
    pop rax
EOS
end
