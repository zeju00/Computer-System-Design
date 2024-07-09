#include <stdio.h>
#include <stdint.h>

int initial() {
    int32_t *addr = (int32_t *)0x400000; // start location
    int32_t value = -1024; // start value
    int32_t end_value = 2048; // end value
    int range = end_value - value + 1; // # of iteration

    int index = 0; // index of memory location
    for (int32_t i = 0; i < range; i++) {
        int32_t current_value = value + i;
        if (current_value == 0) {
            continue; // if value is 0
        }
        addr[index] = current_value; // set value in memory location
        index++; // move to next address
    }

    return 0;
}
