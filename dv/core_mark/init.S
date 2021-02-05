.global _start

_start:
  la sp,0x40008000
  csrw mtvec, t0
  csrr t0,mstatus
  or t0, t0, 0x8
  csrw mstatus, t0
  call main
  j loop

loop:
  j loop

