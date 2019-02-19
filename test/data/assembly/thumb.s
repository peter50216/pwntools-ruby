# arch: thumb
# These tests are fetched from Capstone's test_arm.c
# Thumb
  80001000:   60 f9 1f 04  vld3.8  {d16, d17, d18}, [r0:0x40]
  80001004:   e0 f9 4f 07  vld4.16 {d16[1], d17[1], d18[1], d19[1]}, [r0]
  80001008:   70 47        bx      lr
# PC-relative is buggy in Capstone3, skip it
# 8000100a:   00 f0 10 e8 blx     #0x8000102c
  8000100a:   eb 46        mov     fp, sp
  8000100c:   83 b0        sub     sp, #0xc
  8000100e:   c9 68        ldr     r1, [r1, #0xc]
# PC-relative is buggy in Capstone3, skip it
# 80001010:   1f b1        cbz     r7, #0x8000101e
  80001010:   30 bf        wfi
  80001012:   af f3 20 84  cpsie.w f
  80001016:   52 f8 23 f0  ldr.w   pc, [r2, r3, lsl #2]

# Thumb-mixed
  80001000:   d1 e8 00 f0  tbb   [r1, r0]
  80001004:   f0 24        movs  r4, #0xf0
  80001006:   04 07        lsls  r4, r0, #0x1c
  80001008:   1f 3c        subs  r4, #0x1f
  8000100a:   f2 c0        stm   r0!, {r1, r4, r5, r6, r7}
  8000100c:   00 00        movs  r0, r0
  8000100e:   4f f0 00 01  mov.w r1, #0
  80001012:   46 6c        ldr   r6, [r0, #0x44]

# Thumb-2 & register named with numbers
  80001000:   4f f0 00 01  mov.w     r1, #0
  80001004:   bd e8 00 88  pop.w     {fp, pc}
  80001008:   d1 e8 00 f0  tbb       [r1, r0]
  8000100c:   18 bf        it        ne
  8000100e:   ad bf        iteet     ge
  80001010:   f3 ff 0b 0c  vdupne.8  d16, d11[1]
  80001014:   86 f3 00 89  msr       cpsr_fc, r6
  80001018:   80 f3 00 8c  msr       apsr_nzcvqg, r0
  8000101c:   4f fa 99 f6  sxtb.w    r6, sb, ror #8
  80001020:   d0 ff a2 01  vaddw.u16 q8, q8, d18
