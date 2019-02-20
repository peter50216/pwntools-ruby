# context: endian: big
# This test is (almost) same as powerpc64.s
  1000:   43 20 0c 07  bdnzla+  0xc04
  1004:   41 56 ff 17  bdztla   4*cr5+eq, 0xffffffffffffff14
  1008:   80 20 00 00  lwz      1, 0(0)
  1010:   80 3f 00 00  lwz      1, 0(31)
  1014:   10 43 23 0e  vpkpx    2, 3, 4
  1018:   d0 44 00 80  stfs     2, 0x80(4)
  101c:   4c 43 22 02  crand    2, 3, 4
  1020:   2d 03 00 80  cmpwi    cr2, 3, 0x80
  1024:   7c 43 20 14  addc     2, 3, 4
  1028:   7c 43 20 93  mulhd.   2, 3, 4
  102c:   4f 20 00 21  bdnzlrl+
  1030:   4c c8 00 21  bgelrl-  cr2
  1034:   40 82 00 14  bne      0x1044

# This instruction in ppc32 only
  0:   7c 21 04 a6  mfsr 1, 1
