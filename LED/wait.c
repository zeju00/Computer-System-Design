#include <stdio.h>
#define csd_SWI_ADDR 0x41210000

void wait(){

	int* ptr = csd_SWI_ADDR; // pointer points switch address
	int a = *ptr; // store switch information to variable a
	int count = 1; // time counter
	int no_swi = 1; // no_swi is 1 when no switch turned on

	for (int i=1; i<=8; i++){ // loop for check SW0 ~ SW7
		if (a % 2 == 1){ // to ignore other lower switch
			no_swi = 0; // switch is turned on
			break; // break loop
		}
		a = a >> 1; // bit shift to get next switch position
		count = count + 1; // increment time counter
	}

	if (no_swi) count = count + 2; // if every switch is turned off, time counter is set to 10

	for (int i=0; i<count; i++){ // measure time
		for (int j=0; j<7000000; j++){ // if inner loop executed 10 times, it is 1 second
			continue; // continue loop
		}
	}
}
