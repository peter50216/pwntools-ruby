require 'pwnlib/shellcraft/shellcraft'
::Pwnlib::Shellcraft.define('amd64.popad') do
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
