// ------------------------------------------
//  Author: Prof. Taeweon Suh
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   May 29, 2022
// ------------------------------------------

// Vector table base location should be aligned at 2^5
.align 5
// --------------------------
// Our interrupt vector table
// --------------------------
csd_vector_table:
	b .
	b .
	b .
	b csd_prefetch_abort
	b csd_data_abort
	b .
	b .
	b .

.extern initial

.global main
main:

	// -------------------------------------
	// Set VBAR (Vector Base Address Register) to
	// the base location of our interrupt vector table
	// -------------------------------------
	ldr     r0, =csd_vector_table
	mcr     p15, 0, r0, c12, c0, 0
	dsb
	isb

	// read SCTLR (System Control Register) to r0
	mrc	p15, 0, r0, c1, c0, 0

	// read SCR (Secure Configuration Register) to r1
	mrc p15, 0, r1, c1, c1, 0

	// read TTBCR (Translation Table Base Control Register) to r2
	mrc p15, 0, r2, c2, c0, 2

	// read TTBR0 to r3
	mrc p15, 0, r3, c2, c0, 0

	// read DACR (Domain Access Control Register) to r4
	mrc p15, 0, r4, c3, c0, 0

	/* Disable MMU, if enabled */
	mrc	p15, 0, r0, c1, c0, 0		/* read CP15 register 1 */
	bic	r0, r0, #0x1			/* clear bit 0 */
	mcr	p15, 0, r0, c1, c0, 0		/* write value back */

	/* Invalidate caches and TLBs */
	mov	r0,#0				/* r0 = 0  */
	mcr	p15, 0, r0, c8, c7, 0		/* invalidate TLBs */
	mcr	p15, 0, r0, c7, c5, 0		/* invalidate icache */
	mcr	p15, 0, r0, c7, c5, 6		/* Invalidate branch predictor array */

    // initialize main memory
	bl initial

	ldr	r0, =csd_MMUTable	   /* Load MMU translation table base */
	orr	r0, r0, #0x5B			/* Outer-cacheable, WB */
	mcr	15, 0, r0, c2, c0, 0		/* TTBR0 */

	// Clear PD0 in TTBCR (Translation Table Base Control Register)
	mrc p15, 0, r2, c2, c0, 2
	bic r2, r2, #(1<<4)   // Set PD0 to 0 = HW-based page table walk
	mcr p15, 0, r2, c2, c0, 2

	/* Enable MMU */
	// Set M-bit in SCTLR (System Control Register)
	mrc	p15, 0, r0, c1, c0, 0
	bic r0, r0, #(1<<12)  // I-bit = I$ disable
	bic r0, r0, #(1<<2)   // C-bit = $ disable
	orr r0, r0, #(1<<0)   // M-bit = MMU enable
	mcr	p15, 0, r0, c1, c0, 0	/* Enable MMU */
	dsb					        /* dsb	allow the MMU to start up */
	isb					        /* isb	flush prefetch buffer */

	// read SCTLR (System Control Register) to r0
	mrc	p15, 0, r0, c1, c0, 0

	ldr r0, =0x200000 // start location
	ldr r1, =0x203000 // end location
	mov r2, #0 // register to store sum
	bl sum
	b forever

sum:
	cmp r0, r1
	moveq pc, lr

	ldr r3, [r0], #4
	add r2, r2, r3
	b sum

forever:
	nop
	b forever

csd_prefetch_abort:
	mrc p15, 0, r10, c6, c0, 2  // read IFAR to r10
	mrc p15, 0, r11, c5, c0, 1  // read IFSR to r11
	b .

csd_data_abort:
	mrc p15, 0, r10, c6, c0, 0  // read DFAR to r10
	mrc p15, 0, r11, c5, c0, 0  // read DFSR to r11
	b .
