# arch: i386
# simple move
  0:   b8 5d 00 00 00  mov eax, 0x5d

# pwntools-python's shellcraft.sh()
   0:   6a 68                 push 0x68
   2:   68 2f 2f 2f 73        push 0x732f2f2f
   7:   68 2f 62 69 6e        push 0x6e69622f
   c:   89 e3                 mov  ebx, esp
   e:   68 01 01 01 01        push 0x1010101
  13:   81 34 24 72 69 01 01  xor  dword ptr [esp], 0x1016972
  1a:   31 c9                 xor  ecx, ecx
  1c:   51                    push ecx
  1d:   6a 04                 push 4
  1f:   59                    pop  ecx
  20:   01 e1                 add  ecx, esp
  22:   51                    push ecx
  23:   89 e1                 mov  ecx, esp
  25:   31 d2                 xor  edx, edx
  27:   6a 0b                 push 0xb
  29:   58                    pop  eax
  2a:   cd 80                 int  0x80
