#include "csd_zynq_peripherals.h"
#include "uart_init.s"

#define	TIMER_INITIAL	0x10000

.align 5

csd_vector_table:
	b .
	b .
	b .
	b .
	b .
	b .
	b csd_IRQ_ISR
	b .

.extern task1_c
.extern task2_c
.extern task3_c

.global main
main:

	// Disable interrupt: CPSR'I = 1
	cpsID i

	cps #0x12	   	       // IRQ mode
	ldr	r13,=irq_stack_top // Stack pointer setup for IRQ mode

	cps #0x13		          // supervisor mode
	ldr	r13,=svc_stack_top // Stack pointer setup for SVC mode

	cps #0x1F	             // SYS mode

	// Set VBAR (Vector Base Address Register) to my vector table
	ldr     r0, =csd_vector_table
	mcr     p15, 0, r0, c12, c0, 0
	dsb
	isb

	// Enable interrupt: CPSR'I = 0
	cpsIE i

	cps #0x13

// ---------------------------
// tcb setup - Start
// ---------------------------
	// tcb and tcb_ptr for each task is managed by Empty Ascending

	// task1 tcb and stack setup
	ldr r1, =task1_c
	add r1, r1, #4

	// load top position of stack and tcb_ptr's address
	ldr r2, =task1_stack_top
	ldr r3, =task1_tcb_ptr

	// store stack's top position at tcb_ptr's sp position
	// -> tcb_ptr: r0 - r1 - r2 - ... - r12 - sp - lr
	// -> location of sp at tcb_ptr is tcb_ptr + (4 * 13)
	str r2, [r3, #52]

	// load tcb address and store lr at task1_tcb
	// -> tcb: spsr - lr
	// -> location of lr at tcb is tcb + 4
	ldr r3, =task1_tcb
	str r1, [r3, #4]

	// set to user mode
	mov r1, #0x10
	str r1, [r3]

	// setup procedure of stack of task2 and task3 is same as task1

	// task2 tcb and stack setup
	ldr r1, =task2_c
	add r1, r1, #4
	ldr r2, =task2_stack_top
	ldr r3, =task2_tcb_ptr
	str r2, [r3, #52]
	ldr r3, =task2_tcb
	str r1, [r3, #4]
	mov r1, #0x10
	str r1, [r3]

	// task3 tcb and stack setup
	ldr r1, =task3_c
	add r1, r1, #4
	ldr r2, =task3_stack_top
	ldr r3, =task3_tcb_ptr
	str r2, [r3, #52]
	ldr r3, =task3_tcb
	str r1, [r3, #4]
	mov r1, #0x10
	str r1, [r3]

// ---------------------------
// tcb setup - Start
// ---------------------------

// ---------------------------
// Generic Interrupt Controller (GIC) setup - Begin
// ---------------------------

	// Distributor Control Register
	ldr r0, =GICD_CTLR
	ldr r1, [r0]
	mov r2, #1       // Enable
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

	 // Interrupt Set-Enable Register 0
	ldr r0, =GICD_ISENABLER0
	ldr r1, [r0]
	mov r2, #1 << 29   // Enable #29 (Private Timer)
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

	// According to specifications,
	// Cortex-A9 supports 5-bit version of priority format [7:3] in secure world
	// ( 0 -> 8 -> 16 -> 24...)

	// Interrupt Priority Register #7
	ldr r0, =GICD_PRIOR7
	ldr r1, [r0]
	mov r2, #0x10 << 8    // Priority 16 for ID# 29 (Private Timer)
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

	// CPU Interface Control Register
	ldr r0, =GICC_CTLR
	ldr r1, [r0]
	mov r2, #1        // Enable
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

 	// CPU Interface Interrupt Priority Mask Register
	ldr r0, =GICC_PMR
	ldr r1, [r0]
	mov r2, #0xFF     // Lowest
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

// ---------------------------
// Generic Interrupt Controller (GIC) setup - End
// ---------------------------


// ---------------------------
// Private Timer setup - Begin
// ---------------------------

 	// Private Timer Load Register
	ldr r0, =PRIVATE_LOAD
 	ldr r1, =TIMER_INITIAL
 	str r1, [r0]

 	// Private Timer Control Register
  	ldr r0, =PRIVATE_CONTROL
 	mov r1, #4 << 8   // Prescalar
 	orr r1, r1, #7     // IRQ Enable, Auto-Reload, Timer Enable
 	str r1, [r0]

// ----------------------------
// Private Timer setup - End
// ----------------------------

// ----------------------------
// UART setup - Start
// ----------------------------
	UART_init
// ----------------------------
// UART setup - End
// ----------------------------

	// user mode
	cps #0x10
	ldr sp, =task1_stack_top
	b task1_c

// ----------------------------
// Interrupt Service Routines (ISRs) - Begin
// ----------------------------

csd_IRQ_ISR:
	// backup current task's registers in user mode
	stm sp, {r0-r12, sp, lr}^
	// backup task's cpsr and lr
	mrs r0, spsr
	stmfd sp!, {r0, lr}

	// interrupt ack
	ldr r0, =GICC_IAR
	ldr r1, [r0]

	// clear timer interrupt status bit
	ldr r0, =PRIVATE_STATUS
	mov r2, #1
	str r2, [r0]

	// end of interrupt
	ldr r0, =GICC_EOIR
	str r1, [r0]

	// indicate what task is current task
	ldr r0, =current
	ldr r1, [r0]

	// branch to next task's routine
	cmp r1, #1
	beq task2

	cmp r1, #2
	beq task3

	cmp r1, #3
	beq task1

// task3 -> task1
task1:
	// r0 is set to 'current' address before branching
	mov r1, #1
	str r1, [r0]

	// store spsr and lr of previous task to its tcb
	// spsr and lr is stored in irq stack
	ldmfd sp!, {r0, r1}
	ldr r2, =task3_tcb
	stmea r2, {r0, r1}

	// we use r0 and r1 in this routine, so we have to store registers seperately

	// storing r2-r12, sp, lr
	// skip r0 and r1
	add r0, sp, #8
	// load r2-r12, sp, lr
	ldmfd r0, {r2-r12, sp, lr}
	ldr r1, =task3_tcb_ptr
	// skip location of r0 and r1 in tcb_ptr
	add r1, r1, #8
	stmea r1, {r2-r12, sp, lr}

	// storing r0 and r1
	sub sp, r0, #8
	// load r0 and r1
	ldmfd sp, {r0, r1}
	ldr r2, =task3_tcb_ptr
	stmea r2, {r0, r1}

	// load next task's information
	ldr sp, =task1_tcb
	// load spsr
	ldr r0, [sp]
	// apply next task's spsr
	msr spsr, r0

	// load registers
	ldr sp, =task1_tcb_ptr
	// load registers from user mode
	ldm sp, {r0-r12, sp, lr}^
	ldr sp, =task1_tcb
	// skip location of spsr
	add sp, sp, #4
	// load lr
	ldr lr, [sp]

	// back to irq_sp
	ldr sp, =irq_stack_top

	subs pc, lr, #4

// procedure for task2 and task3 are same as task1

// task1 -> task2
task2:
	mov r1, #2
	str r1, [r0]

	ldmfd sp!, {r0, r1}
	ldr r2, =task1_tcb
	stmea r2, {r0, r1}

	add r0, sp, #8
	ldmfd r0, {r2-r12, sp, lr}

	ldr r1, =task1_tcb_ptr
	add r1, r1, #8
	stmea r1, {r2-r12, sp, lr}

	sub sp, r0, #8
	ldmfd sp, {r0, r1}
	ldr r2, =task1_tcb_ptr
	stmea r2, {r0, r1}

	ldr sp, =task2_tcb
	ldr r0, [sp]
	msr spsr, r0

	ldr sp, =task2_tcb_ptr
	ldm sp, {r0-r12, sp, lr}^
	ldr sp, =task2_tcb
	add sp, sp, #4
	ldr lr, [sp]

	ldr sp, =irq_stack_top

	subs pc, lr, #4

// task2 -> task3
task3:
	mov r1, #3
	str r1, [r0]

	ldmfd sp!, {r0, r1}
	ldr r2, =task2_tcb
	stmea r2, {r0, r1}

	add r0, sp, #8
	ldmfd r0, {r2-r12, sp, lr}

	ldr r1, =task2_tcb_ptr
	add r1, r1, #8
	stmea r1, {r2-r12, sp, lr}

	sub sp, r0, #8
	ldmfd sp, {r0, r1}
	ldr r2, =task2_tcb_ptr
	stmea r2, {r0, r1}

	ldr sp, =task3_tcb
	ldr r0, [sp]
	msr spsr, r0

	ldr sp, =task3_tcb_ptr
	ldm sp, {r0-r12, sp, lr}^
	ldr sp, =task3_tcb
	add sp, sp, #4
	ldr lr, [sp]

	ldr sp, =irq_stack_top

	subs pc, lr, #4

// ----------------------------
// Interrupt Service Routines (ISRs) - End
// ----------------------------

.data
.align 4

user_stack:    .space 1024
user_stack_top:
irq_stack:     .space 1024
irq_stack_top:
svc_stack:     .space 1024
svc_stack_top:

task1_stack:   .space 1024
task1_stack_top:
task2_stack:   .space 1024
task2_stack_top:
task3_stack:   .space 1024
task3_stack_top:

// for each tcb, store spsr and lr
// -> 2 * 4 = 8
// for each tcb_ptr, store r0-r12, sp and lr
// -> 15 * 4 = 60
task1_tcb:     .space 8
task1_tcb_ptr: .space 60
task2_tcb:     .space 8
task2_tcb_ptr: .space 60
task3_tcb:     .space 8
task3_tcb_ptr: .space 60

current: .word 1
