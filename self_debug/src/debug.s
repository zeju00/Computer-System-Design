#include "uart_regs.h"

.macro UART_debug

stmfd sp!, {r0-r12} 	// backup registers in stack
add r0, sp, #52			// store sp(before executing macro) in r0
mov r1, lr				// store lr(before executing macro) in r1
sub r2, pc, #24			// store pc(before executing macro) in r2
mrs r3, cpsr			// store cpsr in r3

ldr r11, =uart_Channel_sts_reg0
ldr r12, =uart_TX_RX_FIFO0

ldr r4, =13f // seperator
bl 1f // print_string


ldr r5, =10f // memory location of backup_registers
mov r7, #0 // reg num
bl 3f // loop

// cpsr
ldr r4, =14f // cpsr
bl 1f // print

// n
ldr r4, =0x80000000
and r5, r3, r4
cmp r5, r4
ldreq r9, =0x4e // N
ldrne r9, =0x6e // n
bl 2f

// z
ldr r4, =0x40000000
and r5, r3, r4
cmp r5, r4
ldreq r9, =0x5a // Z
ldrne r9, =0x7a // z
bl 2f

// c
ldr r4, =0x20000000
and r5, r3, r4
cmp r5, r4
ldreq r9, =0x43 // C
ldrne r9, =0x63 // c
bl 2f

// v
ldr r4, =0x10000000
and r5, r3, r4
cmp r5, r4
ldreq r9, =0x56 // V
ldrne r9, =0x76 // v
bl 2f

//,
ldr r4, =12f
bl 1f

// i
ldr r4, =0x80
and r5, r3, r4
cmp r5, r4
ldreq r9, =0x49 // I
ldrne r9, =0x69 // i
bl 2f

// f
ldr r4, =0x40
and r5, r3, r4
cmp r5, r4
ldreq r9, =0x46 // F
ldrne r9, =0x66 // f
bl 2f

//", "
ldr r4, =12f
bl 1f

// arm thumb jazelle
ldr r2, =0x01000020
and r5, r3, r2

cmp r5, #0
ldreq r4, =15f // arm_mode

cmp r5, #0x20
ldreq r4, =16f // thumb_mode

cmp r5, #0x01000000
ldreq r4, =17f // jazelle_mode

cmp r5, r2
ldreq r4, =18f // thumbee_mode

bl 1f

// processor mode
and r5, r3, #0b11111

cmp r5, #0b10000
ldreq r4, =19f // user_mode

cmp r5, #0b10001
ldreq r4, =20f // fiq_mode

cmp r5, #0b10010
ldreq r4, =21f // irq_mode

cmp r5, #0b10011
ldreq r4, =22f // svc_mode

cmp r5, #0b10110
ldreq r4, =23f // monitor_mode

cmp r5, #0b10111
ldreq r4, =24f // abort_mode

cmp r5, #0b11010
ldreq r4, =25f // hyp_mode

cmp r5, #0b11011
ldreq r4, =26f // undefined_mode

cmp r5, #0b11111
ldreq r4, =27f // system_mode

bl 1f

// cpsr
ldr r5, =0xF0000000
mov r6, #28
mov r4, r3

bl 5f // register_value

// ")"
ldr r9, =0x29
bl 2f

// \r\n
ldr r4, =11f // line feed
bl 1f
// cpsr end

ldr r4, =13f
bl 1f

// recover cpsr
msr cpsr_all, r3

// recover registers
ldr r14, =10f
ldmia r14!, {r0-r12}
ldr r14, [r14]

b 6f // end

1: // print
	push {lr}
	ldrb r9, [r4], #1

	bl 2f

	cmp r9, #0
	bne 1b

	pop {lr}
	moveq pc, lr

2: // transmit
	ldr r10, [r11]
	and r10, r10, #0x10
	cmp r10, #0x10
	beq 2b

	strb r9, [r12]

	mov pc, lr

3: // loop_register
	ldmfd sp!, {r4} 			// load registers from stack
	str r4, [r5], #4			// store value to recover registers
	push {r5}					// store memory location for recovery

	// r0 - r12
	push {lr}
	bl 4f // print
	pop {lr}

	add r7, r7, #1

	cmp r7, #13
	popne {r5}					// pop memory location
	bne 3b // loop

	// r13
	push {lr}
	mov r4, r0
	bl 4f // print
	add r7, r7, #1
	pop {lr}

	// r14
	// backup lr
	pop {r5}
	str r1, [r5]

	push {lr}
	mov r4, r1
	bl 4f // print
	add r7, r7, #1
	pop {lr}

	// r15
	push {lr}
	mov r4, r2
	bl 4f // print
	add r7, r7, #1
	pop {lr}

	mov pc, lr

4: // print
	push {lr}
	// "r{num} = 0x"
	ldr r9, =0x72 // r
	bl 2b // transmit

	// if reg num is greater than 10, print from first digit
	mov r8, r7

	cmp r7, #10
	ldrge r9, =0x31
	subge r8, r7, #10
	blge 2b // transmit

	// first digit of reg num
	add r9, r8, #48
	bl 2b // transmit

	ldr r9, =0x20 // ' '
	bl 2b // transmit

	// if reg num has only one digit, print ' ' twice
	cmp r7, #10
	bllt 2b // transmit

	ldr r9, =0x3d // =
	bl 2b // transmit

	ldr r9, =0x20 // ' '
	bl 2b // transmit

	ldr r9, =0x30 // 0
	bl 2b // transmit

	ldr r9, =0x78 // x
	bl 2b // transmit

	ldr r5, =0xF0000000
	mov r6, #28

	bl 5f // register_value

	// check if register printed 4 times
	cmp r7, #3
	cmpne r7, #7
	cmpne r7, #11
	cmpne r7, #15

	ldreq r4, =11f // line feed
	ldrne r4, =12f // ,
	bl 1b // print

	pop {lr}
	mov pc, lr


5: // register_value
	// extract 4 bits and shift to next 4 bits
	and r9, r4, r5
	lsr r9, r9, r6

	cmp r9, #10
	addlt r9, r9, #48
	addge r9, r9, #87

	push {lr}
	bl 2b
	pop {lr}

	lsr r5, r5, #4
	sub r6, r6, #4

	cmp r6, #12
	moveq r9, #95 // _
	pusheq {lr}
	bleq 2b
	popeq {lr}

	cmp r6, #-4
	bne 5b

	mov pc, lr

	.ltorg

6:
	nop

.data
.align 4
10: // backup_registers
	.space 56, 0x0

11: // line feed
	.byte 0x0d
	.byte 0x0a
	.byte 0x00

12: // ,
	.ascii ", "
	.byte 0x00

13:
	.ascii "--------------------------------------------------------------------------"
	.byte 0x0D
	.byte 0x0A
	.byte 0x00

14: // cpsr
	.ascii "cpsr = "
	.byte 0x00

15: // arm_mode
	.ascii "ARM mode, current mode = "
	.byte 0x00

16: // thumb_mode
	.ascii "Thumb mode, current mode = "
	.byte 0x00

17: // jazelle_mode
	.ascii "Jazelle mode, current mode = "
	.byte 0x00

18: // thumbee_mode
	.ascii "ThumbEE mode, current mode = "
	.byte 0x00

19: // user_mode
	.ascii "USR ( =0x"
	.byte 0x00

20: // fiq_mode
	.ascii "FIQ ( =0x"
	.byte 0x00

21: // irq_mode
	.ascii "IRQ ( =0x"
	.byte 0x00

22: // svc_mode
	.ascii "SVC ( =0x"
	.byte 0x00

23: // monitor_mode
	.ascii "MON ( =0x"
	.byte 0x00

24: // abort_mode
	.ascii "ABT ( =0x"
	.byte 0x00

25: // hyp_mode
	.ascii "HYP ( =0x"
	.byte 0x00

26: // undefined_mode
	.ascii "UND ( =0x"
	.byte 0x00

27: // system_mode
	.ascii "SYS ( =0x"
	.byte 0x00

.text
.endm
