################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

S_SRCS += \
../src/uart_init.s 

C_SRCS += \
../src/platform.c \
../src/task1_c.c \
../src/task2_c.c \
../src/task3_c.c 

S_UPPER_SRCS += \
../src/csd_asm.S 

OBJS += \
./src/csd_asm.o \
./src/platform.o \
./src/task1_c.o \
./src/task2_c.o \
./src/task3_c.o \
./src/uart_init.o 

S_UPPER_DEPS += \
./src/csd_asm.d 

C_DEPS += \
./src/platform.d \
./src/task1_c.d \
./src/task2_c.d \
./src/task3_c.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.S
	@echo 'Building file: $<'
	@echo 'Invoking: ARM v7 gcc compiler'
	arm-none-eabi-gcc -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -IC:/Users/zeju0/Desktop/class_experiments_v21/csd_platform/export/csd_platform/sw/csd_platform/standalone_domain/bspinclude/include -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM v7 gcc compiler'
	arm-none-eabi-gcc -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -IC:/Users/zeju0/Desktop/class_experiments_v21/csd_platform/export/csd_platform/sw/csd_platform/standalone_domain/bspinclude/include -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.s
	@echo 'Building file: $<'
	@echo 'Invoking: ARM v7 gcc assembler'
	arm-none-eabi-gcc -c  -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


