// ------------------------------------------
//  Author: Prof. Taeweon Suh
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   April 27, 2020
// ------------------------------------------

#include "uart_init.s"
#include "debug.s"

.global main

main:
	UART_init     // UART Initialization
	UART_debug

	ldr r0, =Input_data // copy input data to r0
 	ldr r1, =Output_data // copy output data to r1

 	mov r2, #0 // outer_loop counter
 	mov r3, #0 // inner_loop counter
 	mov r9, #0 // initialize max value
 	UART_debug

outer_loop:
	mov r10, r0 // r10 is iterater
	mov r4, r9// min value

	add r2, r2, #1 // increment outer_loop counter
 	cmp r2, #32 // check outer_loop counter is reached to the end
 	streq r4, [r1] // add last element
 	beq forever // outer_loop end
	UART_debug

	cmp r2, #1 // check if first loop
	beq first_loop // go to first loop

	b inner_loop // branch to inner loop

first_loop:
	cmp r3, #32 // if loop counter end
	moveq r3, #0 // initialize loop counter

	streq r4, [r1] // store min value into output_data
 	ldreq r11, [r1] // r11 points last element of output_data
 	addeq r1, r1, #4 // add r1 + 4
 	beq outer_loop // go back to outer_loop

	ldr r5, [r10], #4 // load a word into r5

	cmp r5, r9 // check r5 is bigger than max value
	movge r9, r5 // max value of input data

	subs r6, r5, r4 // compare r5 and min value

	movlt r4, r5 // update min value

	add r3, r3, #1 // increment inner_loop counter
	b first_loop

inner_loop:
	cmp r3, #32 // if loop counter end
	moveq r3, #0 // initialize inner_loop counter
 	streq r4, [r1] // store min value into output_data
 	ldreq r11, [r1] // r11 points last element of output_data
 	addeq r1, r1, #4 // add r1 + 4
 	beq outer_loop // go back to outer_loop

	ldr r5, [r10], #4 // load a word into r5

	cmp r5, r11 // check r5 if there is same value in output_data
	addle r3, r3, #1 // increment loop counter
	ble inner_loop // continue loop

	subgts r6, r5, r4 // compare r5 and min value
	movlt r4, r5 // update min value

	add r3, r3, #1 // increment inner_loop counter
	b inner_loop // iterate inner_loop

forever:
	nop
 	b forever

.data
.align 4
Input_data: .word 2,0,-7,-1,3,8,-4,10
			.word -9,-16,15,13,1,4,-3,14
			.word -8,-10,-15,6,-13,-5,9,12
			.word -11,-14,-6,11,5,7,-2,-12

Output_data: .word 0,0,0,0,0,0,0,0
			 .word 0,0,0,0,0,0,0,0
			 .word 0,0,0,0,0,0,0,0
			 .word 0,0,0,0,0,0,0,0


.text
