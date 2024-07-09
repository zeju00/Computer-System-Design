
.globl  csd_MMUTable
.section .csd_mmu_tbl,"a"

csd_MMUTable:
	/* A 32-bit is required for each PTE (Page Table Entry).
	 * Each PTE covers a 1MB section.
	 * There are 4096 PTEs, so 16KB is required for the page table.
	 *
	 *  First 6 PTEs with the following translations
	 *     1st 1MB: 0x0000_0000 (VA) -> 0x0000_0000 (PA)
	 *     2nd 1MB: 0x0010_0000 (VA) -> 0x0020_0000 (PA)
	 *     3rd 1MB: level 2 page table
	 */
.set SECT, 0
.word	SECT + 0x15de6		/* S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1 */
.set	SECT, SECT + 0x100000
.word	SECT + 0x15de6		/* S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1 */
.set	SECT, SECT + 0x100000
.word	csd_MMUTable_lv2 + 0x1e1		/* S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1 */

.rept (0x200 - 6)
.word	SECT + 0x15de6		/* S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1 */
.endr

.globl csd_MMUTable_lv2
.section .csd_mmu_tbl, "a"

csd_MMUTable_lv2:
	/* Figure 2 */
/*
.align 10
.word 0x400002
.word 0x401002
.word 0x402002
*/
	/* Figure 3 */

.align 10
.word 0x400002
.word 0x402002
.word 0x400002

.end
