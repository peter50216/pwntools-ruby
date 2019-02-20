# These tests are fetched from Capstone's test_arm.c
  1000:   ed ff ff eb  bl    #0xfbc
  1004:   04 e0 2d e5  str   lr, [sp, #-4]!
  1008:   00 00 00 00  andeq r0, r0, r0
  100c:   e0 83 22 e5  str   r8, [r2, #-0x3e0]!
  1010:   f1 02 03 0e  mcreq p2, #0, r0, c3, c1, #7
  1014:   00 00 a0 e3  mov   r0, #0
  1018:   02 30 c1 e7  strb  r3, [r1, r2]
  101c:   00 00 53 e3  cmp   r3, #0
