def popad
  cat <<EOS
    pop rdi
    pop rsi
    pop rbp
    pop rsp
    pop rbp
    pop rdx
    pop rcx
    pop rax
EOS
end
