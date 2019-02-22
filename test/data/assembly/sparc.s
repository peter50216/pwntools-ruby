# These tests are fetched from Capstone's test_sparc.c

# !skip asm # because of keystone-engine/keystone#405
  1000:   80 a0 40 02  cmp     %g1, %g2
  1004:   85 c2 60 08  jmpl    %o1+8, %g2
  1008:   85 e8 20 01  restore %g0, 1, %g2
  100c:   81 e8 00 00  restore
  1010:   90 10 20 01  mov     1, %o0
  1014:   d5 f6 10 16  casx    [%i0], %l6, %o2
  1018:   21 00 00 0a  sethi   0xa, %l0
  101c:   86 00 40 02  add     %g1, %g2, %g3
  1020:   01 00 00 00  nop
  1024:   12 bf ff ff  bne     0x1020
  1028:   10 bf ff ff  ba      0x1024
  102c:   a0 02 00 09  add     %o0, %o1, %l0
  1030:   0d bf ff ff  fbg     0x102c
  1034:   d4 20 40 00  st      %o2, [%g1]
  1038:   d4 4e 00 16  ldsb    [%i0+%l6], %o2
# The output between objdump/llvm/capstone is inconsistent
  ; 103c:   2a c2 80 03  brnz,a,pn %o2, 0x1048

# Copied from above, ignored branch instructions
  1000:   80 a0 40 02  cmp     %g1, %g2
  1004:   85 e8 20 01  restore %g0, 1, %g2
  1008:   81 e8 00 00  restore
  100c:   90 10 20 01  mov     1, %o0
  1010:   d5 f6 10 16  casx    [%i0], %l6, %o2
  1014:   21 00 00 0a  sethi   0xa, %l0
  1018:   86 00 40 02  add     %g1, %g2, %g3
  101c:   01 00 00 00  nop
  1020:   a0 02 00 09  add     %o0, %o1, %l0
  1024:   d4 20 40 00  st      %o2, [%g1]
  1028:   d4 4e 00 16  ldsb    [%i0+%l6], %o2
