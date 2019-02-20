# context: endian: little
# These tests are fetched from Capstone's test_mips.c
# MIPS-64-EL (Little-endian)
  1000:   56 34 21 34  ori $at, $at, 0x3456
  1004:   c2 17 01 00  srl $v0, $at, 0x1f
  1008:   70 00 b2 ff  sd  $s2, 0x70($sp)
