# arch: aarch64
# These tests are fetched from Capstone's test_arm64.c
# ARM-64
  2c:   09 00 38 d5  mrs   x9, midr_el1
  30:   bf 40 00 d5  msr   spsel, #0
  34:   0c 05 13 d5  msr   dbgdtrtx_el0, x12
  38:   20 50 02 0e  tbx   v0.8b, {v1.16b, v2.16b, v3.16b}, v2.8b
  3c:   20 e4 3d 0f  scvtf v0.2s, v1.2s, #3
  40:   00 18 a0 5f  fmla  s0, s0, v0.s[3]
  44:   a2 00 ae 9e  fmov  x2, v5.d[1]
  48:   9f 37 03 d5  dsb   nsh
  4c:   bf 33 03 d5  dmb   osh
  50:   df 3f 03 d5  isb
  54:   21 7c 02 9b  mul   x1, x1, x2
  58:   21 7c 00 53  lsr   w1, w1, #0
  5c:   00 40 21 4b  sub   w0, w0, w1, uxtw
  60:   e1 0b 40 b9  ldr   w1, [sp, #8]
  64:   20 04 81 da  cneg  x0, x1, ne
  68:   20 08 02 8b  add   x0, x1, x2, lsl #2
  6c:   10 5b e8 3c  ldr   q16, [x24, w8, uxtw #4]
