# arch: amd64
# simple move
  0:   b8 17 00 00 00 mov     eax, 0x17

# pwntools-python's shellcraft.sh()
   0:   6a 68                         push    0x68
   2:   48 b8 2f 62 69 6e 2f 2f 2f 73 movabs  rax, 0x732f2f2f6e69622f
   c:   50                            push    rax
   d:   48 89 e7                      mov     rdi, rsp
  10:   68 72 69 01 01                push    0x1016972
  15:   81 34 24 01 01 01 01          xor     dword ptr [rsp], 0x1010101
  1c:   31 f6                         xor     esi, esi
  1e:   56                            push    rsi
  1f:   6a 08                         push    8
  21:   5e                            pop     rsi
  22:   48 01 e6                      add     rsi, rsp
  25:   56                            push    rsi
  26:   48 89 e6                      mov     rsi, rsp
  29:   31 d2                         xor     edx, edx
  2b:   6a 3b                         push    0x3b
  2d:   58                            pop     rax
  2e:   0f 05                         syscall
