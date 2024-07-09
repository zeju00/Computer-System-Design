// ------------------------------------------
//  Author: Prof. Taeweon Suh
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   March 29, 2020
// ------------------------------------------

#define csd_LED_ADDR 0x41200000

.extern wait

.global main

main:
 	ldr r0, =csd_LED_ADDR // r0 is LED ADDR
 	mov r1, #0b10000000 // r1 is storage of LED ADDR
 	str r1, [r0] // initialize LED ADDR to 10000000

exec:
	bl wait // go to c code to determine which switch is on

	cmp r1, #1 // check if LED 1 is on
	moveq r1, #0b10000000 // go back to LED 8 if LED 1 is on
	rorne r1, r1, #1 // go to next LED
	str r1, [r0] // LED on

	b exec // go back to loop

.data
.align 4

