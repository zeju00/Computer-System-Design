#include "csd_zynq_peripherals.h"

.extern csd_main

.global main

main:
	ldr r0, =csd_SW_ADDR
	ldr r1, [r0] // SW data register
	and r2, r1, #0b00000001
	cmp r2, #0

	bleq disable
	blne enable
	// Read Cache Type Register (CTR)
	mrc p15, 0, r1, c0, c0, 1

	// Read Cache Level ID Register (CLIDR)
	mrc p15, 1, r2, c0, c0, 1

	bl csd_main
	b main

disable:
	@------------------------
	@ Disable Caches (L2)
	@------------------------
	ldr r0, =L2_reg1_ctrl
	mov r1, #0x0
	str r1, [r0]
	@------------------------
	@ Disable Caches (IL1, DL1)
	@------------------------
	mrc	p15, 0, r0, c1, c0, 0	@ read control register (CP15 register1)
	bic	r0, r0, #4096		    @ disable I bit (Instruction Cache)
	bic	r0, r0, #4		        @ disable C bit (Data and Unified Caches)
	mcr	p15, 0, r0, c1, c0, 0	@ write control register (CP15 register2)
	// read SCTLR (System Control Register) to r0

	mrc	p15, 0, r0, c1, c0, 0

	mov pc, lr

enable:
	@------------------------
	@ Enable Caches (L2)
	@------------------------
	ldr r0, =L2_reg1_ctrl
    mov r1, #0x1
    str r1, [r0]

	@------------------------
	@ Enable Caches (IL1, DL1)
	@------------------------
	mrc	p15, 0, r0, c1, c0, 0	@ read control register (CP15 register1)
	orr	r0, r0, #(1<<12)	    @ Enable I bit (Instruction Cache)
	orr	r0, r0, #(1<<2)         @ Enable C bit (Data and Unified Caches)
	mcr	p15, 0, r0, c1, c0, 0	@ write control register (CP15 register2)
	// read SCTLR (System Control Register) to r0
	mrc	p15, 0, r0, c1, c0, 0
	mov pc, lr
