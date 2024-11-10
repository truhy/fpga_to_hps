################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../FreeRTOS/Source/croutine.c \
../FreeRTOS/Source/event_groups.c \
../FreeRTOS/Source/list.c \
../FreeRTOS/Source/queue.c \
../FreeRTOS/Source/stream_buffer.c \
../FreeRTOS/Source/tasks.c \
../FreeRTOS/Source/timers.c 

OBJS += \
./FreeRTOS/Source/croutine.o \
./FreeRTOS/Source/event_groups.o \
./FreeRTOS/Source/list.o \
./FreeRTOS/Source/queue.o \
./FreeRTOS/Source/stream_buffer.o \
./FreeRTOS/Source/tasks.o \
./FreeRTOS/Source/timers.o 

C_DEPS += \
./FreeRTOS/Source/croutine.d \
./FreeRTOS/Source/event_groups.d \
./FreeRTOS/Source/list.d \
./FreeRTOS/Source/queue.d \
./FreeRTOS/Source/stream_buffer.d \
./FreeRTOS/Source/tasks.d \
./FreeRTOS/Source/timers.d 


# Each subdirectory must supply rules for building sources it contributes
FreeRTOS/Source/%.o: ../FreeRTOS/Source/%.c FreeRTOS/Source/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU Arm Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-a9 -marm -mfloat-abi=hard -mfpu=neon -mno-unaligned-access -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -DDEBUG -Dsoc_cv_av -DCYCLONEV -DALT_INT_PROVISION_VECTOR_SUPPORT=0 -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\bsp" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\hwlib\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\hwlib\include\soc_cv_av" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\trulib\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\streamer\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\FreeRTOS\Source\include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\FreeRTOS\Source\portable\GCC\ARM_CA9" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\CMSIS\Core\Include" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\CMSIS\Core\Include\a-profile" -I"D:\Documents\Programming\FPGA\de10nano-c-verilog\f2s_stream\20241019 - with m10k bram 256\f2s_stream_bram_c\source\CMSIS\Device\c5soc\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


