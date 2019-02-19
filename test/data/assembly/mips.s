# arch: mips, endian: big
# These tests are fetched from Capstone's test_mips.c
# MIPS-32 (Big-endian)
  1000:   0c 10 00 97  jal   0x40025c
  1004:   00 00 00 00  nop
  1008:   24 02 00 0c  addiu $v0, $zero, 0xc
  100c:   8f a2 00 00  lw    $v0, ($sp)
  1010:   34 21 34 56  ori   $at, $at, 0x3456
